[Problem]
  kernel_coverage_check = false
  material_coverage_check = false
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

[Variables]
  [d]
    block = 0
    [InitialCondition]
      type = FunctionIC
      function = 'if((abs(y-${H}/2)<0.01) & x<${a}+0.05, 1, 0)'
    []
  []
[]

[AuxVariables]
  [interface]
  []
  [bounds_dummy]
    block = 0
  []
  [psie_active]
    order = CONSTANT
    family = MONOMIAL
  []
  [effective_creep_strain]
    order = CONSTANT
    family = MONOMIAL
  []
[]

# [AuxKernels]
#   [interface]
#     type = FunctionAux
#     variable = interface
#     # This is the actual growth rate:
#     # function = 'x-1.468e-5*sqrt(t)-${a}'
#     # But it is too slow, so I increased it
#     function = 'x-1.468e-4*sqrt(t)-${a}-0.2'
#     execute_on = 'INITIAL LINEAR TIMESTEP_END'
#   []
# []

[Bounds]
  [irreversibility]
    type = VariableOldValueBoundsAux
    variable = bounds_dummy
    bounded_variable = d
    bound_type = lower
    block = 0
  []
  [upper]
    type = ConstantBoundsAux
    variable = bounds_dummy
    bounded_variable = d
    bound_type = upper
    bound_value = 1
    block = 0
  []
[]

[Kernels]
  [ACBulk]
    type = AllenCahn
    variable = d
    f_name = F
  []
  [ACInterface]
    type = ACInterface
    variable = d
    kappa_name = kappa
    variable_L = false
    mob_name = L
  []
[]

[Materials]
  [fracture_properties]
    type = GenericConstantMaterial
    prop_names = 'l psic Gc c0 xi'
    prop_values = '${l} ${psic} ${Gc} ${fparse 8/3} 1'
    block = 0
  []
  [mobility]
    type = ParsedMaterial
    f_name = L
    material_property_names = 'Gc c0 l'
    function = 'Gc/c0/l'
    constant_on = SUBDOMAIN
    block = 0
  []
  [interface_coef]
    type = ParsedMaterial
    f_name = kappa
    material_property_names = 'l'
    function = '2*l*l'
    constant_on = SUBDOMAIN
    block = 0
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
    block = 0
  []
  [crack_geometric_function]
    type = DerivativeParsedMaterial
    f_name = w
    args = 'd'
    function = 'd'
    derivative_order = 2
    block = 0
  []
  [gc]
    type = ParsedMaterial
    f_name = gc
    args = effective_creep_strain
    function = '1-(1-beta)*(1-exp(-effective_creep_strain/ep0))'
    constant_names = 'beta ep0'
    constant_expressions = '${beta} ${ep0}'
    block = 0
  []
  [free_energy]
    type = DerivativeParsedMaterial
    f_name = F
    args = 'd psie_active'
    material_property_names = 'w(d) g(d) gc Gc c0 l'
    function = 'gc*w*Gc/c0/l+g*psie_active'
    derivative_order = 2
    block = 0
  []
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -snes_type'
  petsc_options_value = 'lu vinewtonrsls'

  nl_rel_tol = 1e-08
  nl_abs_tol = 1e-10
  nl_max_its = 100

  dt = 1e20

  automatic_scaling = true

  max_xfem_update = 1
[]

[Outputs]
  print_linear_residuals = false
[]
