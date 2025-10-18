local image_name = std.extVar('image_name');
local image_tag = std.extVar('image_tag');

local common_labels(name) = {
  'app.kubernetes.io/name': name,
  'app.kubernetes.io/instance': name,
};

{
  namespace(namespace):: {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: namespace,
    },
  },

  configMap(name, namespace, data={}):: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common_labels(name),
    },
    data: data,
  },

  deployment(name, namespace):: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common_labels(name),
    },
    spec: {
      selector: {
        matchLabels: common_labels(name),
      },
      template: {
        metadata: {
          labels: common_labels(name),
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

  hpa(name, namespace, min=1, max=1):: {
    apiVersion: 'autoscaling/v2',
    kind: 'HorizontalPodAutoscaler',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common_labels(name),
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

  serviceAccount(name, namespace):: {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common_labels(name),
    },
    automountServiceAccountToken: true,
  },

  service(name, namespace, type='ClusterIP'):: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: name,
      namespace: namespace,
      labels: common_labels(name),
    },
    spec: {
      type: type,
      selector: common_labels(name),
      ports: [
        {
          name: 'http',
          port: 8080,
          targetPort: 8080,
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
}
