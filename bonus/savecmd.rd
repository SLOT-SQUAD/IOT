kubectl port-forward service/argocd-server -n argocd 8080:443
kubectl port-forward svc/gitlab-webservice-default -n gitlab 8082:8181
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath='{.data.password}' | base64 -d; echo
kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab \
  -o jsonpath='{.data.password}' | base64 -d; echo
