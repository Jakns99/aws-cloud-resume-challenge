resource "aws_lambda_function" "myfunc" {
    filename       = data.archive_file
}