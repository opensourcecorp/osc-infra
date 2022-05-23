infracode
====

She lay with Heaven and bore the Titans
---------------------------------------

---

OpenSourceCorp's [Terraform
module](https://www.terraform.io/docs/language/modules/index.html) repository.

Gaia is home to two features:

* Terraform modules that other projects can use to deploy into OSC.

* Module calls to itself to deploy OSC's core infrastructure. See the `infracode/`
  subdirectory for more details & examples.

OpenSourceCorp aims to target multiple platforms (with a preference towards
eventual self-hosting), and so has support for multiple [Terraform
Providers](https://www.terraform.io/docs/language/providers/index.html) which
you will find grouped under the `providers/` subdirectory.

How to use
----------

In your own repository, provide a `infracode` module address as your module `source`,
*[noting the two slashes](https://www.terraform.io/docs/language/modules/sources.html#modules-in-package-sub-directories)*:

    source = https://github.com/opensourcecorp/osc-infra//infracode/providers/<provider>/<module_name>

Where `<provider>` is the name of the provider, and `<module_name>` is the name
of the module itself within that provider. For example, to use Gaia's AWS EC2
instance module, you might provide that `source` as:

    module "ec2_instance" {
      source = https://github.com/opensourcecorp/osc-infra//infracode/providers/aws/ec2_instance
    }
