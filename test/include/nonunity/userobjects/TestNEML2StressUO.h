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

#pragma once

#include "neml2/models/Model.h"

#include "BatchMaterial.h"

#include "RankTwoTensor.h"
#include "RankFourTensor.h"
#include "SymmetricRankTwoTensor.h"
#include "SymmetricRankFourTensor.h"

typedef BatchMaterial<BatchMaterialUtils::TupleStd,
                      std::pair<RankTwoTensor, RankFourTensor>,
                      BatchMaterialUtils::GatherMatProp<RankTwoTensor>>
    TestNEML2StressUOParent;

class TestNEML2StressUO : public TestNEML2StressUOParent
{
public:
  static InputParameters validParams();

  TestNEML2StressUO(const InputParameters & params);

  virtual void batchCompute();

protected:
  std::array<Real, 6> R2TtoSymR2T(const RankTwoTensor & from) const;
  RankTwoTensor SymR2TtoR2T(torch::Tensor from) const;
  RankFourTensor SymSymR4TtoR4T(torch::Tensor symsymr4t) const;

  std::shared_ptr<neml2::Model> _model;

private:
  const FileName _fname;
  const std::string _mname;
  const bool _verbose;
};
