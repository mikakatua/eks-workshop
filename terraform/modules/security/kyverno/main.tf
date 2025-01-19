resource "helm_release" "kyverno" {
  namespace        = "kyverno"
  create_namespace = true

  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno"
  version    = var.module_inputs.kyverno_chart_version
  wait       = true
}

resource "helm_release" "kyverno_policies" {
  namespace = "kyverno"

  name       = "kyverno-policies"
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno-policies"
  version    = var.module_inputs.kyverno_policies_chart_version
  wait       = true

  values = [
    <<-EOT
    podSecurityStandard: privileged
    EOT
  ]

  depends_on = [helm_release.kyverno]
}

