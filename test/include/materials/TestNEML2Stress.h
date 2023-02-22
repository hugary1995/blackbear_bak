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

#include "TestNEML2StressUO.h"
#include "ComputeLagrangianStressCauchy.h"

class TestNEML2Stress : public ComputeLagrangianStressCauchy
{
public:
  static InputParameters validParams();
  TestNEML2Stress(const InputParameters & parameters);

protected:
  virtual void computeProperties();
  virtual void computeQpCauchyStress();

  const TestNEML2StressUO & _neml2_uo;
  const TestNEML2StressUO::OutputVector & _output;
};
