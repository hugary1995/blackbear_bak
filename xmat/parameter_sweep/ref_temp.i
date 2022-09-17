T_gas = '${fparse 1100}'
T_steam = '${fparse 530}'

[Mesh]
  use_displaced_mesh = false
  [refined]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = ${a}
    xmax = ${b}
    ymin = 0
    ymax = ${H}
    nx = 50 # hx = 1/50 = 0.02
    ny = 200 # hy = 4/200 = 0.02
  []
  [coarse]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = ${b}
    xmax = ${c}
    ymin = 0
    ymax = ${H}
    nx = 4
    ny = 200
  []
  [stitch]
    type = StitchedMeshGenerator
    inputs = 'refined coarse'
    stitch_boundaries_pairs = 'right left'
  []
  [left]
    type = SubdomainBoundingBoxGenerator
    input = stitch
    block_id = 0
    bottom_left = '${a} 0 0'
    top_right = '${b} ${H} 0'
  []
  [right]
    type = SubdomainBoundingBoxGenerator
    input = left
    block_id = 1
    bottom_left = '${b} 0 0'
    top_right = '${c} ${H} 0'
  []
[]

[Problem]
  coord_type = RZ
[]

[Variables]
  [temp]
  []
[]

[Kernels]
  [conduction]
    type = HeatConduction
    variable = 'temp'
  []
[]

[BCs]
  [convection_inner]
    type = ConvectiveHeatFluxBC
    variable = 'temp'
    boundary = 'left'
    T_infinity = ${T_steam}
    heat_transfer_coefficient = ${h_steam}
  []
  [convection_outer]
    type = ConvectiveHeatFluxBC
    variable = 'temp'
    boundary = 'right'
    T_infinity = ${T_gas}
    heat_transfer_coefficient = ${h_gas}
  []
[]

[Materials]
  [thermal_metal]
    type = GenericConstantMaterial
    prop_names = 'thermal_conductivity'
    prop_values = '${kappa_metal}'
  []
[]

[Executioner]
  type = Transient
  solve_type = 'NEWTON'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu       superlu_dist                 '
  automatic_scaling = true

  nl_rel_tol = 1e-06
  nl_abs_tol = 1e-08

  num_steps = 1
[]

[Outputs]
  print_linear_converged_reason = false
  print_nonlinear_converged_reason = false
  print_linear_residuals = false
[]
