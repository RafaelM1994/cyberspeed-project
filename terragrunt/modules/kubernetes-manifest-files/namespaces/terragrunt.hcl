include {
  path = find_in_parent_folders()
}

locals {


  module      = split("/", "${path_relative_to_include()}")[1] #Get full path 'environment/modules/module', split into 2 strings and get the last one
  submodule = split("/", "${path_relative_to_include()}")[2] #Get full path 'environment/modules/module/submodule', split into 3 strings and get the last one
  common_vars        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.inputs.environment
  variables  = { for file in fileset("../../../${local.environment}/${local.module}/${local.submodule}", "*.yaml") :
    trimsuffix(file, ".yaml") => yamldecode(file("../../../${local.environment}/${local.module}/${local.submodule}/${file}"))
  }

}

inputs = merge(
  local.common_vars.inputs,
  {
    namespaces = {
      for k, v in local.variables : k => merge(v, {
          environment       = try(v.environment, local.environment)
        })
    }
  }
)