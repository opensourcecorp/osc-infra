# U BETTER NOT USE THESE IRL
harbor_admin_password: 'Harbor12345' # this is the default from their docs

harbor_http_port: 8080
harbor_https_port: 443

harbor_dbs:
  port: 5432
  harbor_core:
    dbname: harbor_core
    user: harbor
    password: harbor
  notary_server:
    dbname: harbor_notary_server
    user: harbor
    password: harbor
  notary_signer:
    dbname: harbor_notary_signer
    user: harbor
    password: harbor
