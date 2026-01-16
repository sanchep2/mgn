# ------------------------------------------------------------------------
# Providers for both regions
# ------------------------------------------------------------------------

provider "aws" {
  region  = "us-east-1"
  alias   = "us_east_1"
  profile = "wrk"
}

provider "aws" {
  region  = "us-east-2"
  alias   = "us_east_2"
  profile = "wrk"
}
