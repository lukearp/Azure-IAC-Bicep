# What is this for?
Script to create self-signed certificates with a common Root CA cert for HTTPs demos.

# Parameters
param | type | notes
------|------|------
RootcertName | String | Name of the cert created as Root
DNSNames | Array | Array of FQDNS that will have Certs created for off Root.
OutPath | String | Path to were exported Certificates will be exported to
certPassword | String | Password for PFX files

# How to use?
```powershell
.\Self-Signed-Certs.ps1 -RootcertName "Script-Test" -DNSNames @("test.lukemsdemos.com","anothertest.lukemsdemos.com") -OutPath C:\Users\user\Documents\My-TestCerts -certPassword 1234
```