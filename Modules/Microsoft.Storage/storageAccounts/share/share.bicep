param shareName string
param storageAccountName string

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${storageAccountName}/default/${shareName}'
}
