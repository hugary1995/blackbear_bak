/****************************************************************/
/*               DO NOT MODIFY THIS HEADER                      */
/*                       BlackBear                              */
/*                                                              */
/*           (c) 2017 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/

#ifdef NEML2_ENABLED

#include "neml2/base/HITParser.h"
#include "TestNEML2StressUO.h"
#include "MathUtils.h"

registerMooseObject("BlackBearTestApp", TestNEML2StressUO);

InputParameters
TestNEML2StressUO::validParams()
{
  auto params = TestNEML2StressUOParent::validParams();
  params.addRequiredParam<MaterialPropertyName>("strain", "The name of strain");
  params.addRequiredParam<FileName>("input", "Path to input file containing the NEML2 model");
  params.addRequiredParam<std::string>("model", "Model name in the NEML2 input file");
  params.addParam<bool>(
      "verbose",
      false,
      "Set to true to print additional information during the batched computation.");
  return params;
}

TestNEML2StressUO::TestNEML2StressUO(const InputParameters & params)
  : TestNEML2StressUOParent(params, "strain"),
    _fname(getParam<FileName>("input")),
    _mname(getParam<std::string>("model")),
    _verbose(getParam<bool>("verbose"))
{
  neml2::HITParser parser;
  parser.parse_and_manufacture(_fname);
  _model = neml2::Factory::get_object_ptr<neml2::Model>("Models", _mname);
}

void
TestNEML2StressUO::batchCompute()
{
  neml2::TorchSize nbatch = _input_data.size();

  // First create a torch::Tensor from the Blackbear input data
  if (_verbose)
    _console << COLOR_CYAN << name() << ": Converting Blackbear input data to NEML2 format"
             << COLOR_DEFAULT << std::endl;
  std::vector<std::array<Real, 6>> neml_strains(nbatch);
  for (const auto i : index_range(_input_data))
    neml_strains[i] = R2TtoSymR2T(std::get<0>(_input_data[i]));
  neml2::LabeledVector in(torch::from_blob(&neml_strains[0][0], {nbatch, 6}, TorchDefaults),
                          _model->input());

  // Let NEML2 do the batched computation
  if (_verbose)
    _console << COLOR_CYAN << name() << ": Performing batched constitutive update using NEML2"
             << COLOR_DEFAULT << std::endl;
  torch::NoGradGuard no_grad_guard;
  const auto [out, dout_din] = _model->value_and_dvalue(in);
  const auto stress = out.slice("state")("cauchy_stress");
  const auto dstress_dstrain = dout_din.block("state", "state")("cauchy_stress", "elastic_strain");

  // Fill the NEML2 output back into the Blackbear output data
  if (_verbose)
    _console << COLOR_CYAN << name() << ": Converting NEML2 output data to Blackbear format"
             << COLOR_DEFAULT << std::endl;
  for (const neml2::TorchSize i : index_range(_output_data))
  {
    std::get<0>(_output_data[i]) = SymR2TtoR2T(stress.batch_index({i}));
    std::get<1>(_output_data[i]) = SymSymR4TtoR4T(dstress_dstrain.batch_index({i}));
  }
}

std::array<Real, 6>
TestNEML2StressUO::R2TtoSymR2T(const RankTwoTensor & r2t) const
{
  SymmetricRankTwoTensor symr2t(r2t);
  return {symr2t(0), symr2t(1), symr2t(2), symr2t(3), symr2t(4), symr2t(5)};
}

RankTwoTensor
TestNEML2StressUO::SymR2TtoR2T(torch::Tensor symr2t) const
{
  Real * vals = symr2t.data_ptr<Real>();
  return RankTwoTensor(vals[0] / SymmetricRankTwoTensor::mandelFactor(0),
                       vals[1] / SymmetricRankTwoTensor::mandelFactor(1),
                       vals[2] / SymmetricRankTwoTensor::mandelFactor(2),
                       vals[3] / SymmetricRankTwoTensor::mandelFactor(3),
                       vals[4] / SymmetricRankTwoTensor::mandelFactor(4),
                       vals[5] / SymmetricRankTwoTensor::mandelFactor(5));
}

RankFourTensor
TestNEML2StressUO::SymSymR4TtoR4T(torch::Tensor symsymr4t) const
{
  // Full tensor indices in the Mandel representation
  static constexpr unsigned int g[6][6][4] = {
      {{1, 1, 1, 1}, {1, 1, 2, 2}, {1, 1, 3, 3}, {1, 1, 2, 3}, {1, 1, 1, 3}, {1, 1, 1, 2}},
      {{2, 2, 1, 1}, {2, 2, 2, 2}, {2, 2, 3, 3}, {2, 2, 2, 3}, {2, 2, 1, 3}, {2, 2, 1, 2}},
      {{3, 3, 1, 1}, {3, 3, 2, 2}, {3, 3, 3, 3}, {3, 3, 2, 3}, {3, 3, 1, 3}, {3, 3, 1, 2}},
      {{2, 3, 1, 1}, {2, 3, 2, 2}, {2, 3, 3, 3}, {2, 3, 2, 3}, {2, 3, 1, 3}, {2, 3, 1, 2}},
      {{1, 3, 1, 1}, {1, 3, 2, 2}, {1, 3, 3, 3}, {1, 3, 2, 3}, {1, 3, 1, 3}, {1, 3, 1, 2}},
      {{1, 2, 1, 1}, {1, 2, 2, 2}, {1, 2, 3, 3}, {1, 2, 2, 3}, {1, 2, 1, 3}, {1, 2, 1, 2}}};

  RankFourTensor r4t;
  Real * vals = symsymr4t.data_ptr<Real>();
  for (const auto a : make_range(6))
    for (const auto b : make_range(6))
    {
      const auto i = g[a][b][0] - 1;
      const auto j = g[a][b][1] - 1;
      const auto k = g[a][b][2] - 1;
      const auto l = g[a][b][3] - 1;
      r4t(i, j, k, l) = r4t(j, i, k, l) = r4t(i, j, l, k) = r4t(j, i, l, k) =
          vals[a * 6 + b] / SymmetricRankFourTensor::mandelFactor(a, b);
    }

  return r4t;
}
#endif // NEML2_ENABLED
