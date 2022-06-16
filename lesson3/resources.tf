variable "lambdas" {
  type = list(string)
  default = [
     "idanTest1",
     "idanTest2" 
  ]
}

module "lambda_module" {
  count = length(var.lambdas)
  source = "./modules/lambda"
  lambda_name = var.lambdas[count.index]
}