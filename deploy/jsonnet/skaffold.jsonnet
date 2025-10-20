local common = import './common.libsonnet';
local lib = import './main.libsonnet';

// The canonical environment name
local env = std.extVar('env');
// The generated tag value used for any custom-built images
local image_tag = std.extVar('image_tag');

{
  apiVersion: 'skaffold/v4beta13',
  kind: 'Config',
  metadata: {
    name: 'osc-infra',
  },

  build: {
    platforms: ['linux/amd64'],
    // Have to quote this because 'local' is a reserved word in jsonnet
    'local': {
      push: true,
      useBuildkit: true,
    },
    // artifacts: [
    //   {
    //     image: '',
    //     docker: {
    //       dockerfile: '',
    //       buildArgs: {
    //         k: 'v',
    //       },
    //     },
    //   },
    // ],
  },

  manifests: {
    rawYaml: [
      std.format('./deploy/rendered/%s/*.yaml', env),
    ],
  },

  deploy: {
    statusCheckDeadlineSeconds: 300,
    tolerateFailuresUntilDeadline: true,

    // Should only be used to deploy external Helm charts, i.e. not ones we own
    helm: {
      flags: {
        upgrade: [
          '--history-max=1',
        ],
      },
      releases: [
        {
          name: 'k8s-metrics-server',
          repo: 'https://kubernetes-sigs.github.io/metrics-server',
          remoteChart: 'metrics-server',
          version: '3.13.0',
          namespace: common.SystemNamespace,
          createNamespace: true,
          setValues: {
            args: ['--kubelet-insecure-tls=true'],
          },
          upgradeOnChange: true,
        },
        {
          name: 'load-balancer',
          repo: 'https://metallb.github.io/metallb',
          remoteChart: 'metallb',
          version: '0.15.2',
          namespace: common.SystemNamespace,
          createNamespace: true,
          upgradeOnChange: true,
        },
        // TODO: get this working, it's mad about the LBAnnotations value
        // {
        //   name: 'monitoring',
        //   remoteChart: 'oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack',
        //   version: '78.3.2',
        //   namespace: common.SystemNamespace,
        //   createNamespace: true,
        //   setValues: {
        //     // NOTE: this top-level field is in the *dependencies* for this Chart, which is why you
        //     // won't be able to find it there
        //     grafana: {
        //       service: {
        //         type: 'LoadBalancer',
        //         annotations+: common.LBAnnotations,
        //       },
        //     },
        //   },
        //   upgradeOnChange: true,
        // },
      ],
    },

    // NOTE: determined by the manifests section above.
    kubectl: {},
  },
}
