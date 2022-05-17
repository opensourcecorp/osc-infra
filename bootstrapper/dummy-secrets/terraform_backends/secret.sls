# U BETTER NOT USE THESE IRL
terraform_backends:
  configmgmt:
    pg:
      dbname: terraform_backend_configmgmt
      dbuser: tf_user_configmgmt
      dbpass: passwd
  atlas:
    pg:
      dbname: terraform_backend_atlas
      dbuser: tf_user_atlas
      dbpass: passwd
  datastore:
    pg:
      dbname: terraform_backend_datastore
      dbuser: tf_user_datastore
      dbpass: passwd
  cicd:
    pg:
      dbname: terraform_backend_cicd
      dbuser: tf_user_cicd
      dbpass: passwd
  monitor:
    pg:
      dbname: terraform_backend_monitor
      dbuser: tf_user_monitor
      dbpass: passwd
  padl:
    pg:
      dbname: terraform_backend_padl
      dbuser: tf_user_padl
      dbpass: passwd
  ociregistry:
    pg:
      dbname: terraform_backend_ociregistry
      dbuser: tf_user_ociregistry
      dbpass: passwd
  sourcecode:
    pg:
      dbname: terraform_backend_sourcecode
      dbuser: tf_user_sourcecode
      dbpass: passwd
