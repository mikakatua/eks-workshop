# Custom Networking

If the subnet CIDR is too small, the CNI may not be able to acquire enough secondary IP addresses to assign to your Pods. This is a common challenge for EKS IPv4 clusters. Custom networking addresses the IP exhaustion issue by assigning the Pod IPs from secondary VPC address spaces (CIDR).

When custom networking is enabled, the VPC CNI creates secondary ENIs in the subnet and assigns Pods an IP address from the CIDR range defined in a ENIConfig CRD.

> [!NOTE]
> Custom networking can mitigate IP exhaustion issues, but it requires additional operational overhead. If you are currently deploying a dual-stack (IPv4/IPv6) VPC or if your plan includes IPv6 support, we recommend implementing IPv6 clusters instead. Please review best practices for [Running IPv6 EKS Clusters](https://docs.aws.amazon.com/eks/latest/best-practices/ipv6.html).