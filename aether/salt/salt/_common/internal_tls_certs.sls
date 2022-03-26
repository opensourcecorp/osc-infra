get_root_ca_key:
  file.managed:
  - name: /tmp/osc-ca.key
  - source: salt://osc-ca.key
  - mode: 0600
  - makedirs: true
  - replace: true

create_certs_directory:
  file.directory:
  - name: /etc/ssl/custom

create_x509v3_cert_extension_config:
  file.managed:
  - name: /tmp/{{ pillar['app_name'] }}.ext
  - replace: true
  - contents: |
      authorityKeyIdentifier=keyid,issuer
      basicConstraints=CA:FALSE
      keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
      subjectAltName = @alt_names

      [alt_names]
      DNS.1 = {{ pillar['app_name'] }}.service.consul

create_tls_cert:
  cmd.run:
  - name: |
      openssl genrsa -out /etc/ssl/private/{{ pillar['app_name'] }}.key 4096
      chmod 0600 /etc/ssl/private/{{ pillar['app_name'] }}.key

      openssl req \
        -new \
        -subj '/C=US/ST=MO/L=Any/O=OpenSourceCorp/OU=App/CN={{ pillar['app_name'] }}/emailAddress=admin@opensourcecorp.org' \
        -key /etc/ssl/private/{{ pillar['app_name'] }}.key \
        -out /tmp/{{ pillar['app_name'] }}.csr

      openssl x509 \
        -req \
        -CA /etc/ssl/certs/osc-ca.pem \
        -CAkey /tmp/osc-ca.key \
        -CAcreateserial \
        -days 1825 \
        -sha256 \
        -extfile /tmp/{{ pillar['app_name'] }}.ext \
        -in /tmp/{{ pillar['app_name'] }}.csr \
        -out /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt
  - creates:
    - /etc/ssl/private/{{ pillar['app_name'] }}.key
    - /tmp/{{ pillar['app_name'] }}.csr
    - /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt

# Also need to edit some perms on existing files so system app users can access them
set_perms_for_apps:
  cmd.run:
  - name: |
      # Need to add a system user just in case, individual States can always modify the User later
      grep -q {{ salt['pillar.get']('system_user', pillar['app_name']) }} /etc/passwd || useradd {{ salt['pillar.get']('system_user', pillar['app_name']) }}
      chown \
        root:{{ salt['pillar.get']('system_user', pillar['app_name']) }} \
        /etc/ssl/private/{{ pillar['app_name'] }}.key \
        /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt \
        /usr/local/share/ca-certificates/osc-ca.crt
      chmod \
        0640 \
        /etc/ssl/private/{{ pillar['app_name'] }}.key \
        /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt \
        /usr/local/share/ca-certificates/osc-ca.crt
      # Surprise! Immediate parent dirs need execute perms for reading files within them
      chmod 0755 /etc/ssl/private /usr/local/share/ca-certificates

# check_cert_validity:
#   tls.valid_certificate:
#   - name: x
#   - weeks: x # is cert still valid within X weeks

# Can't leave the root CA key hanging around on the host
remove_root_ca_key:
  file.absent:
  - name: /tmp/osc-ca.key

update_ca_certificates:
  cmd.run:
  - name: update-ca-certificates
