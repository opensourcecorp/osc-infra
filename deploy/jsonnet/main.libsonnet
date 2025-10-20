local common = import './common.libsonnet';

local image_name = std.extVar('image_name');
local image_tag = std.extVar('image_tag');

{
  Namespace(name): {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: name,
    },
  },

  ConfigMap(name, namespace, data={}): {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common.Labels(name),
    },
    data: data,
  },

  Deployment(name, namespace): {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common.Labels(name),
    },
    spec: {
      selector: {
        matchLabels: common.Labels(name),
      },
      template: {
        metadata: {
          labels: common.Labels(name),
        },
        spec: {
          serviceAccountName: name,
          containers: [
            {
              name: name,
              image: image_name + ':' + image_tag,
              imagePullPolicy: 'IfNotPresent',
              ports: [
                {
                  name: 'http',
                  containerPort: 8080,
                  protocol: 'TCP',
                },
                {
                  name: 'grpc',
                  containerPort: 8082,
                  protocol: 'TCP',
                },
              ],
              // livenessProbe: {
              //   grpc: {
              //     port: 8082,
              //   },
              // },
              envFrom: [
                {
                  configMapRef: { name: name },
                },
              ],
              resources: {
                requests: {
                  cpu: '200m',
                  memory: '256Mi',
                },
                limits: {
                  cpu: '500m',
                  memory: '256Mi',
                },
              },
              volumeMounts: [],
            },
          ],
          volumes: [],
          nodeSelector: {},
          affinity: {},
          tolerations: [],
        },
      },
    },
  },

  HPA(name, namespace, min=1, max=1): {
    apiVersion: 'autoscaling/v2',
    kind: 'HorizontalPodAutoscaler',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common.Labels(name),
    },
    spec: {
      scaleTargetRef: {
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        name: name,
      },
      minReplicas: min,
      maxReplicas: max,
      metrics: [
        {
          type: 'Resource',
          resource: {
            name: 'cpu',
            target: {
              type: 'Utilization',
              averageUtilization: 75,
            },
          },
        },
        {
          type: 'Resource',
          resource: {
            name: 'memory',
            target: {
              type: 'Utilization',
              averageUtilization: 75,
            },
          },
        },
      ],
    },
  },

  ServiceAccount(name, namespace): {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common.Labels(name),
    },
    automountServiceAccountToken: true,
  },

  Service(name, namespace, type='ClusterIP'): {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common.Labels(name),
      annotations: common.LBAnnotations,
    },
    spec: {
      type: type,
      selector: common.Labels(name),
      ports: [
        {
          name: 'http',
          port: 8080,
          targetPort: 80,
          protocol: 'TCP',
        },
        {
          name: 'grpc',
          port: 8082,
          targetPort: 8082,
          protocol: 'TCP',
        },
      ],
    },
  },

  MetalLB_IPAddressPool(lb_ip_addrs=[]): {
    apiVersion: 'metallb.io/v1beta1',
    kind: 'IPAddressPool',
    metadata: {
      name: 'main',
      namespace: common.SystemNamespace,
    },
    spec: {
      addresses: lb_ip_addrs,
    },
  },

  MetalLB_L2Advertisement(): {
    apiVersion: 'metallb.io/v1beta1',
    kind: 'L2Advertisement',
    metadata: {
      name: 'main',
      namespace: common.SystemNamespace,
    },
  },

  MetalLB_BGPAdvertisement(): {
    apiVersion: 'metallb.io/v1beta1',
    kind: 'BGPAdvertisement',
    metadata: {
      name: 'main',
      namespace: common.SystemNamespace,
    },
    spec: {
      ipAddressPools: [
        'main',
      ],
    },
  },
}
