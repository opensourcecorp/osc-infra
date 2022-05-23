# Rename this file to just 'secret.sls'; it'll be gitignored.
# Then you can replace all values as necessary
terraform_backends:
  configmgmt:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
  datastore:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
  netsvc:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
  cicd:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
  monitor:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
  padl:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
  ociregistry:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
  sourcecode:
    pg:
      dbname: dbname
      dbuser: dbuser
      dbpass: dbpass
