# geometry
a = 14
b = 15
c = 25
H = 1

# oxide parameters
E_oxide = 1.2e5
nu_oxide = 0.24
kappa_oxide = 3

# metal parameters
E_metal = 1.9e5
nu_metal = 0.3
kappa_metal = 30

# boundary condition
h_gas = 0.1
h_steam = 2.8

# fracture properties
#####################################
# These two parameters are what we need to tune
# We may need to decrease these parameters to get spallation at the first shut-down event
# The ratio between these two parameters should be kept unchanged.
psic = 0.016
Gc = 0.025
#####################################
# This is the regularization length of the phase field
# If you have a finer mesh, you can decrease this value
l = 0.03 # given element size 0.02
ep0 = 5e-6
beta = 0.2

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[MultiApps]
  [ref_temp]
    type = FullSolveMultiApp
    input_files = 'ref_temp.i'
    app_type = BlackBearApp
    execute_on = 'INITIAL'
    cli_args = 'a=${a};b=${b};c=${c};H=${H};kappa_metal=${kappa_metal};h_gas=${h_gas};h_steam=${h_ste'
               'am}'
  []
[]

[Transfers]
  [from_temp]
    type = MultiAppMeshFunctionTransfer
    direction = from_multiapp
    multi_app = ref_temp
    source_variable = temp
    variable = ref_temp
  []
[]

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
    ny = 50 # hy = 1/50 = 0.02
  []
  [coarse]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = ${b}
    xmax = ${c}
    ymin = 0
    ymax = ${H}
    nx = 4
    ny = 50
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

[XFEM]
  output_cut_plane = true
[]

[UserObjects]
  [cut]
    type = LevelSetCutUserObject
    level_set_var = interface
    negative_id = 0
    positive_id = 1
    heal_always = true
  []
  [subdomain_modifier]
    type = CutElementSubdomainModifier
    geometric_cut_userobject = cut
    apply_initial_conditions = false
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Problem]
  coord_type = RZ
[]

[Functions]
  [CTE_oxide]
    type = PiecewiseLinear
    format = columns
    data_file = 'gold/CTE_oxide.csv'
  []
  [CTE_metal]
    type = PiecewiseLinear
    format = columns
    data_file = 'gold/CTE_metal.csv'
  []
  [T_gas]
    type = VectorPostprocessorFunction
    vectorpostprocessor_name = 'bcs'
    argument_column = 'time'
    value_column = 'T_gas'
  []
  [T_steam]
    type = VectorPostprocessorFunction
    vectorpostprocessor_name = 'bcs'
    argument_column = 'time'
    value_column = 'T_steam'
  []
  [p_gas]
    type = VectorPostprocessorFunction
    vectorpostprocessor_name = 'bcs'
    argument_column = 'time'
    value_column = 'p_gas'
  []
  [p_steam]
    type = VectorPostprocessorFunction
    vectorpostprocessor_name = 'bcs'
    argument_column = 'time'
    value_column = 'p_steam'
  []
  [dt]
    type = VectorPostprocessorFunction
    vectorpostprocessor_name = 'bcs'
    argument_column = 'time'
    value_column = 'dt'
  []
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [temp]
  []
  [d]
    # block = 0
    [InitialCondition]
      type = FunctionIC
      # function = 'if((abs(y-${H}/6)<0.01 | abs(y-${H}/2)<0.01 | abs(y-${H}/6*5)<0.01) & x<${a}+0.05, '
      #            '1, 0)'
      # This is essentially picking three nodes and set the values on them to be 1
      # With a finer mesh, you need to reduce the tolerance 0.01, and shorten the initial crack length 0.05
      function = 'if((abs(y-${H}/2)<0.01) & x<${a}+0.05, 1, 0)'
    []
  []
[]

[AuxVariables]
  [interface]
  []
  [ref_temp]
  []
  [temp_in_K]
  []
  # [d]
  # []
  [bounds_dummy]
    # block = 0
  []
[]

[AuxKernels]
  [interface]
    type = FunctionAux
    variable = interface
    # This is the actual growth rate:
    function = 'x-1.468e-5*sqrt(t)-${a}-0.023'
    # But it is too slow, so I increased it
    # This 0.023 is to prevent cutting along element edges at INITIAL
    # function = 'x-1.468e-4*sqrt(t)-${a}-0.023'
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [temp_in_K]
    type = ParsedAux
    variable = 'temp_in_K'
    args = 'temp'
    function = 'temp + 273.15'
  []
[]

[Bounds]
  [irreversibility]
    type = VariableOldValueBoundsAux
    variable = bounds_dummy
    bounded_variable = d
    bound_type = lower
    # block = 0
  []
  [upper]
    type = ConstantBoundsAux
    variable = bounds_dummy
    bounded_variable = d
    bound_type = upper
    bound_value = 1
    # block = 0
  []
[]

[Kernels]
  [solid_x]
    type = StressDivergenceRZTensors
    variable = 'disp_x'
    temperature = 'temp'
    eigenstrain_names = 'thermal_eigenstrain'
    use_finite_deform_jacobian = false
    component = 0
    use_displaced_mesh = false
  []
  [solid_y]
    type = StressDivergenceRZTensors
    variable = 'disp_y'
    temperature = 'temp'
    eigenstrain_names = 'thermal_eigenstrain'
    use_finite_deform_jacobian = false
    component = 1
    use_displaced_mesh = false
  []
  # [solid_x_off_diag]
  #   type = PhaseFieldFractureMechanicsOffDiag
  #   variable = disp_x
  #   c = d
  #   component = 0
  #   block = 0
  # []
  # [solid_y_off_diag]
  #   type = PhaseFieldFractureMechanicsOffDiag
  #   variable = disp_y
  #   c = d
  #   component = 1
  #   block = 0
  # []
  [conduction]
    type = HeatConduction
    variable = 'temp'
  []
  [ACBulk]
    type = AllenCahn
    variable = d
    f_name = F
    # block = 0
  []
  [ACInterface]
    type = ACInterface
    variable = d
    kappa_name = kappa
    variable_L = false
    mob_name = L
    # block = 0
  []
[]

[Constraints]
  [disp_x]
    type = XFEMSingleVariableConstraint
    variable = 'disp_x'
    geometric_cut_userobject = 'cut'
    alpha = 5e7
    use_penalty = true
  []
  [disp_y]
    type = XFEMSingleVariableConstraint
    variable = 'disp_y'
    geometric_cut_userobject = 'cut'
    alpha = 5e7
    use_penalty = true
  []
  [temp_constraint]
    type = XFEMSingleVariableConstraint
    variable = 'temp'
    geometric_cut_userobject = 'cut'
    alpha = 1e4
    use_penalty = true
  []
  [d_constraint]
    type = XFEMSingleVariableConstraint
    variable = 'd'
    geometric_cut_userobject = 'cut'
    alpha = 100
    use_penalty = true
  []
[]

[BCs]
  [fixed_y]
    type = DirichletBC
    variable = 'disp_y'
    boundary = 'top bottom'
    value = 0
  []
  [convection_left]
    type = ConvectiveHeatFluxBC
    variable = 'temp'
    boundary = 'left'
    T_infinity = T_steam
    heat_transfer_coefficient = ${h_steam}
  []
  [convection_right]
    type = ConvectiveHeatFluxBC
    variable = 'temp'
    boundary = 'right'
    T_infinity = T_gas
    heat_transfer_coefficient = ${h_gas}
  []
  [Pressure]
    [gas]
      boundary = 'right'
      function = p_gas
    []
  []
[]

[Materials]
  [environment]
    type = GenericFunctionMaterial
    prop_names = 'T_gas T_steam'
    prop_values = 'T_gas T_steam'
    constant_on = SUBDOMAIN
  []
  # fracture
  [fracture_properties_oxide]
    type = GenericConstantMaterial
    prop_names = 'l c0 xi'
    prop_values = '${l} ${fparse 8/3} 1'
    # block = 0
  []
  [Gc]
    type = ParsedMaterial
    f_name = Gc
    args = 'interface'
    function = 'if(abs(interface)<0.03, ${Gc}, ${Gc})'
    outputs = exodus
  []
  [psic]
    type = ParsedMaterial
    f_name = psic
    args = 'interface'
    function = 'if(abs(interface)<0.03, ${psic}, ${psic})'
    outputs = exodus
  []
  [fracture_properties_metal]
    type = GenericConstantMaterial
    prop_names = 'psie_active_old'
    prop_values = '0'
    block = 1
  []
  [mobility]
    type = ParsedMaterial
    f_name = L
    material_property_names = 'Gc c0 l'
    function = 'Gc/c0/l'
    constant_on = SUBDOMAIN
    # block = 0
  []
  [interface_coef]
    type = ParsedMaterial
    f_name = kappa
    material_property_names = 'l'
    function = '2*l*l'
    constant_on = SUBDOMAIN
    # block = 0
  []
  [degradation]
    type = DerivativeParsedMaterial
    f_name = g
    args = d
    function = (1-d)^p/((1-d)^p+(Gc/psic*xi/c0/l)*d*(1+a2*d+a2*a3*d^2))*(1-eta)+eta
    constant_names = 'p a2 a3 eta'
    constant_expressions = '2 1 0 1e-6'
    material_property_names = 'Gc psic l xi c0'
    derivative_order = 2
    # block = 0
  []
  [crack_geometric_function]
    type = DerivativeParsedMaterial
    f_name = w
    args = 'd'
    function = 'd'
    derivative_order = 2
    # block = 0
  []
  [gc]
    type = ParsedMaterial
    f_name = gc
    function = '1-(1-beta)*(1-exp(-effective_creep_strain/ep0))'
    constant_names = 'beta ep0'
    constant_expressions = '${beta} ${ep0}'
    material_property_names = 'effective_creep_strain'
    # block = 0
  []
  [free_energy]
    type = DerivativeParsedMaterial
    f_name = F
    args = 'd'
    material_property_names = 'w(d) g(d) gc Gc c0 l psie_active_old'
    function = 'gc*w*Gc/c0/l+g*psie_active_old'
    derivative_order = 2
    # block = 0
  []
  # oxide
  [thermal_oxide]
    type = GenericConstantMaterial
    prop_names = 'thermal_conductivity'
    prop_values = '${kappa_oxide}'
    block = 0
  []
  [eigenstrain_oxide]
    type = ComputeInstantaneousThermalExpansionFunctionEigenstrain
    stress_free_temperature = ref_temp
    temperature = temp
    thermal_expansion_function = CTE_oxide
    eigenstrain_name = 'thermal_eigenstrain'
    block = 0
  []
  [elasticity_tensor_oxide]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = ${E_oxide}
    poissons_ratio = ${nu_oxide}
    block = 0
  []
  [strain_oxide]
    type = ComputeAxisymmetricRZIncrementalStrain
    eigenstrain_names = 'thermal_eigenstrain'
    block = 0
  []
  [creep_oxide]
    type = PowerLawCreepStressUpdate
    coefficient = 8.5875e7
    n_exponent = 3
    activation_energy = 4.2162e8
    gas_constant = 8.3143e3
    temperature = 'temp_in_K'
    block = 0
    outputs = exodus
    output_properties = 'effective_creep_strain'
  []
  [stress_oxide]
    type = PFFComputeMultipleInelasticStress
    inelastic_models = 'creep_oxide'
    c = d
    degradation_function = g
    block = 0
    outputs = exodus
    output_properties = 'stress elastic_strain psie_active'
  []
  # metal
  [thermal_metal]
    type = GenericConstantMaterial
    prop_names = 'thermal_conductivity'
    prop_values = '${kappa_metal}'
    block = 1
  []
  [elasticity_tensor_metal]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = ${E_metal}
    poissons_ratio = ${nu_metal}
    constant_on = SUBDOMAIN
    block = 1
  []
  [eigenstrain_metal]
    type = ComputeInstantaneousThermalExpansionFunctionEigenstrain
    stress_free_temperature = ref_temp
    temperature = temp
    thermal_expansion_function = CTE_metal
    eigenstrain_name = 'thermal_eigenstrain'
    block = 1
  []
  [strain_metal]
    type = ComputeAxisymmetricRZIncrementalStrain
    eigenstrain_names = 'thermal_eigenstrain'
    block = 1
  []
  [creep_metal]
    type = PowerLawCreepStressUpdate
    coefficient = 2.3e6
    n_exponent = 5.06
    activation_energy = 4e8
    gas_constant = 8.3143e3
    temperature = 'temp_in_K'
    block = 1
  []
  [stress_metal]
    type = ComputeMultipleInelasticStress
    inelastic_models = 'creep_metal'
    block = 1
  []
[]

[Postprocessors]
  [years]
    type = FunctionValuePostprocessor
    function = 't/86400/360'
  []
  [damage]
    type = ElementIntegralVariablePostprocessor
    variable = 'd'
  []
[]

[VectorPostprocessors]
  [bcs]
    type = CSVReader
    csv_file = 'gold/BC.csv'
    header = true
  []
[]

[Preconditioning]
  [smp]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -snes_type'
  petsc_options_value = 'lu       strumpack                     vinewtonrsls'
  automatic_scaling = true

  nl_rel_tol = 1e-06
  nl_abs_tol = 1e-06
  nl_forced_its = 1
  nl_max_its = 200

  [TimeStepper]
    type = CSVTimeSequenceStepper
    file_name = 'gold/BC.csv'
    header = true
  []
  end_time = 156744000

  max_xfem_update = 1

  # fixed_point_max_its = 50
  # fixed_point_rel_tol = 1e-06
  # fixed_point_abs_tol = 1e-06
  # accept_on_max_fixed_point_iteration = true
[]

[Outputs]
  print_linear_residuals = false
  print_linear_converged_reason = false
  print_nonlinear_converged_reason = false
  [exodus]
    type = Exodus
    file_base = 'output/elastic_thermal_creep'
    interval = 1
  []
[]
