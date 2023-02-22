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

#ifdef NEML_ENABLED

#include "TestNEML2Stress.h"

registerMooseObject("BlackBearTestApp", TestNEML2Stress);

InputParameters
TestNEML2Stress::validParams()
{
  InputParameters params = ComputeLagrangianStressCauchy::validParams();
  params.addRequiredParam<UserObjectName>("neml2_uo",
                                          "User object that performs the batch computation");
  return params;
}

TestNEML2Stress::TestNEML2Stress(const InputParameters & parameters)
  : ComputeLagrangianStressCauchy(parameters),
    _neml2_uo(getUserObject<TestNEML2StressUO>("neml2_uo")),
    _output(_neml2_uo.getOutputData())
{
}

void
TestNEML2Stress::computeProperties()
{
  if (!_neml2_uo.outputReady())
    return;

  const auto index = _neml2_uo.getIndex(_current_elem->id());

  for (_qp = 0; _qp < _qrule->n_points(); ++_qp)
  {
    _cauchy_stress[_qp] = std::get<0>(_output[index + _qp]);
    _cauchy_jacobian[_qp] = std::get<1>(_output[index + _qp]);
    computeQpProperties();
  }
}

void
TestNEML2Stress::computeQpCauchyStress()
{
}

#endif // NEML_ENABLED
