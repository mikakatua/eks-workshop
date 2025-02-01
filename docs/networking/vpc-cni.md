# Amazon VPC CNI
Amazon EKS officially supports Amazon Virtual Private Cloud (VPC) CNI plugin to implement Kubernetes Pod networking. An EKS cluster consists of two VPCs: an AWS managed VPC that hosts the Kubernetes control plane and a second customer-managed VPC that hosts the Kubernetes worker nodes where containers run, as well as other AWS infrastructure (like load balancers) used by a cluster.

> [!NOTE]
> Pods and nodes are located at the same network layer and share the network namespace.

## Security Groups for Pods
Containerized applications frequently require access to external AWS services, such as Amazon Relational Database Service (Amazon RDS). By default, the Amazon VPC CNI will use security groups associated with the primary ENI on the node and this SG are too coarse grained because they apply to all Pods running on a node. That means that all Pods will have access to the RDS database service.

You can enable security groups for Pods by setting `ENABLE_POD_ENI=true` for VPC CNI. Once enabled, the [VPC Resource Controller](https://github.com/aws/amazon-vpc-resource-controller-k8s) running on the control plane (managed by EKS) creates and attaches a trunk interface called `aws-k8s-trunk-eni` to the node. To manage trunk interfaces, you must add the `AmazonEKSVPCResourceController` managed policy to the cluster role that goes with your Amazon EKS cluster.

The `SecurityGroupPolicy` custom resource applies a security group to a Pod. The VPC resource controller then associates branch interfaces to the trunk interface. The Pods requiring specific security groups are scheduled on the node with these additional network interfaces. The controller adds an annotation with the branch interface details to the pod.

> [!IMPORTANT]
> Security group policies only apply to newly scheduled Pods. They do not affect running Pods.

Use network policies to manage access between Pods rather than security groups if your Pods do not depend on any AWS services within or outside of your VPC. Review [EKS best practices guide](https://docs.aws.amazon.com/eks/latest/best-practices/sgpp.html) for recommendations and [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html), for deployment prerequisites.

> [!WARNING]
> Security groups for Pods are supported by most Nitro-based Amazon EC2 instance families, though not by all generations of a family. For example, the m5, c5, r5, m6g, c6g, and r6g instance family and generations are supported. Instance types in the t family or any small (.small) and medium (.medium) instance types are not supported. For a complete list of supported instance types, see the [limits.go](https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/v1.5.0/pkg/aws/vpc/limits.go) file on GitHub. Your nodes must be one of the listed instance types that have `IsTrunkingCompatible: true` in that file.
