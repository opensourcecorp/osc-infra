{
  // Namespace for all OSC-system-related deployments to live in
  SystemNamespace: 'osc-system',

  LBAnnotations: {
    'metallb.io/address-pool': 'main',
  },

  Labels(name): {
    'app.kubernetes.io/name': name,
    'app.kubernetes.io/instance': name,
  },
}
