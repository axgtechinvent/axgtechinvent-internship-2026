# Ghid de Configurare SSH & Conectare EC2 (`AxgProject`)

Acest ghid explică pașii necesari pentru configurarea cheii SSH locale și conectarea la instanța EC2 (Amazon Linux 2023) creată prin Terraform.

##  Pasul 1: Generarea Perechii de Chei SSH Locale

Fiecare membru al echipei trebuie să aibă generată o pereche de chei SSH în directorul personal `.ssh`.

Deschide terminalul în VS Code și rulează:

1. **Creează directorul `.ssh` (dacă nu există):**
   mkdir ~$env:USERPROFILE\.ssh -ErrorAction SilentlyContinue

2. **Generează cheia SSH:**
   ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa_aws"

     Când ești întrebat de *passphrase*, apasă **Enter** (de două ori) pentru a lăsa cheia fără parolă.

##  Pasul 2: Configurare Variabile Terraform (`terraform.tfvars`)

1. Creează fișierul `terraform.tfvars` în rădăcina proiectului .
2. Adaugă IP-ul tău public curent pentru a permite accesul în Security Group (portul 22):

   my_ip = "X.X.X.X" # Înlocuiește cu IP-ul tău public (află-l de pe https://whatismyip.com !!! ip-urile se schimmba la un anumit interval de timp, deci daca apare eroare "Connection timed out" verifica daca s a schimbat ip-ul)

   Calea către cheia publică implicită este `~/.ssh/id_rsa_aws.pub`. Dacă ți-ai salvat cheia în altă locație, adaugă și variabila `public_key_path` în `terraform.tfvars`:
>  public_key_path = "calea/catre/cheia_ta.pub"

##  Pasul 3: Aplicarea Infrastructurii (Terraform)

Execută comenzile standard în terminal:

terraform init
terraform plan
terraform apply

La finalizarea comenzii `terraform apply`, terminalul va afișa IP-ul public al instanței:

Outputs:
ec2_public_ip = "x.x.x.x"

##  Pasul 4: Conectarea la Instanța EC2

După ce instanța este pornită, conectează-te prin SSH folosind cheia privată creată la Pasul 1 și utilizatorul implicit `ec2-user`:

ssh -i "$env:USERPROFILE\.ssh\id_rsa_aws" ec2-user@IP_PUBLIC_EC2

Când te conectezi prima dată, tastează `yes` și apasă **Enter** pentru a adăuga amprenta serverului în `known_hosts`.
