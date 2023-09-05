helm uninstall mydjango1 && \
sleep 30
helm install -f env-values.yaml mydjango1 ./djangoapp

