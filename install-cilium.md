Scratch notes from when migrating from Flannel and kube-proxy to cilium: 


``` bash
kubectl -n kube-system delete daemonset kube-flannel
kubectl -n kube-system delete daemonset kube-proxy
kubectl -n kube-system delete cm kube-flannel-cfg
kubectl -n kube-system delete cm kube-proxy # noe found
```


