module "lambda_module1" {
  source = "./modules/lambda"
  lambda_name = "idanTest_lambda1"
}

module "lambda_module2" {
  source = "./modules/lambda"
  lambda_name = "idanTest_lambda2"
}