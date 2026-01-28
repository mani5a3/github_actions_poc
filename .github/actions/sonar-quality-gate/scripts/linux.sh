#-----------------linux runner -----------------------------------   
# - name: SonarQube Quality Gate check
#   id: sonarqube-quality-gate-check
#   uses: sonarsource/sonarqube-quality-gate-action@master
#   with:
#     pollingTimeoutSec: 180
#   env:
#     SONAR_TOKEN: ${{ secrets.Sonar_Token }}
#     SONAR_HOST_URL: ${{ secrets.Sonar_HostUrl }}

# # Optionally you can use the output from the Quality Gate in another step.
# # The possible outputs of the `quality-gate-status` variable are `PASSED`, `WARN` or `FAILED`.
# - name: "show SonarQube Quality Gate Status value"
#   run: echo "The Quality Gate status is ${{ steps.sonarqube-quality-gate-check.outputs.quality-gate-status }}"