local env = std.extVar('env');
local image_tag = std.extVar('image_tag');

{
  apiVersion: 'skaffold/v4beta13',
  kind: 'Config',
  metadata: {
    name: 'osc-infra',
  },
  build: {
    platforms: ['linux/amd64'],
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

    // Determined by the manifests section above
    kubectl: {},

    helm: {
      flags: {
        upgrade: [
          '--history-max=1',
        ],
      },
      releases: [
        {
          name: 'metrics-server',
          version: '3.13.0',
          repo: 'https://kubernetes-sigs.github.io/metrics-server',
          remoteChart: 'metrics-server',
          namespace: 'metrics-server',
          createNamespace: true,
          setValues: {
            args: ['--kubelet-insecure-tls=true'],
          },
        },
        {
          name: 'metallb',
          version: '0.15.2',
          repo: 'https://metallb.github.io/metallb',
          remoteChart: 'metallb',
          namespace: 'metallb',
          createNamespace: true,
        },
      ],
    },
  },
}
