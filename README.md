# Ghid de Acces la Instanța EC2 prin AWS Session Manager (`AxgProject`)

Acest ghid explică pașii necesari pentru ca fiecare membru al echipei să obțină acces shell la instanța EC2 (Amazon Linux 2023) creată prin Terraform.

> **Ce s-a schimbat față de versiunea anterioară**
>
> Accesul nu se mai face prin SSH cu chei private, ci prin **AWS Systems Manager Session Manager**. Concret:
>
> - **nu mai generezi chei SSH** — nu mai există nimic de distribuit, de pierdut sau de rotit;
> - **portul 22 este complet închis** — Security Group-ul nu are nicio regulă inbound pentru SSH;
> - **nu mai configurezi `my_ip`** — nu mai contează dacă providerul îți schimbă IP-ul public;
> - **fiecare membru se autentifică cu identitatea lui IAM** — în CloudTrail se vede exact cine a deschis ce sesiune și pe ce instanță;
> - **revocarea accesului** se face scoțând persoana din grupul IAM, nu schimbând o cheie partajată.
>
> Costul suplimentar: **0 USD**. Session Manager pe instanțe EC2 și IAM nu au tarif adițional.

---

## Pasul 1: Instalarea uneltelor locale (o singură dată, pe fiecare laptop)

Ai nevoie de două lucruri: **AWS CLI v2** și **pluginul Session Manager**.

### macOS

```bash
brew install awscli
brew install --cask session-manager-plugin
```

> Dacă terminalul zice `command not found` imediat după instalare, rulează `rehash`. Zsh ține în cache locațiile comenzilor și nu observă binarele noi.

### Windows (PowerShell)

```powershell
winget install --id Amazon.AWSCLI
winget install --id Amazon.SessionManagerPlugin
```

Alternativ, cu Chocolatey:

```powershell
choco install awscli
choco install awscli-session-manager
```

> **Important pe Windows:** după instalare, **închide și redeschide PowerShell**. Installer-ul modifică `PATH`, dar terminalele deja deschise nu văd modificarea.

### Verificare (ambele sisteme)

```bash
aws --version
session-manager-plugin
```

A doua comandă trebuie să afișeze `The Session Manager plugin was installed successfully`.

---

## Pasul 2: Configurarea credențialelor AWS (o singură dată)

Fiecare membru folosește **propriile** credențiale IAM — nu se partajează chei între colegi.

```bash
aws configure
```

Completează:

| Câmp | Valoare |
|---|---|
| AWS Access Key ID | cheia ta personală |
| AWS Secret Access Key | secretul tău personal |
| Default region name | `eu-central-1` |
| Default output format | `json` |

Verifică cu ce identitate ești autentificat:

```bash
aws sts get-caller-identity
```

> Regiunea este obligatorie. Dacă regiunea implicită nu este `eu-central-1`, instanța nu va fi găsită și va trebui să adaugi `--region eu-central-1` la fiecare comandă.

---

## Pasul 3: Acordarea accesului echipei (o singură dată, făcut de cel care rulează Terraform)

Accesul la shell este controlat de un grup IAM definit în `ssm-team-access.tf`. Adaugă numele utilizatorilor IAM în `terraform.tfvars`:

```hcl
team_members = ["alin", "coleg2", "coleg3"]
```

Numele trebuie să fie **utilizatori IAM care există deja** în cont (aceiași cu care se face login în consolă). Terraform nu îi creează.

---

## Pasul 4: Aplicarea infrastructurii (Terraform)

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

La final vei vedea:

```
Outputs:

ec2_operators_group  = "AxgProject-ec2-operators-dev"
instance_id          = "i-0a1b2c3d4e5f67890"
public_dns           = "ec2-x-x-x-x.eu-central-1.compute.amazonaws.com"
public_ip            = "x.x.x.x"
s3_bucket_name       = "axgproject-storage-dev-ab12cd"
ssm_connect_command  = "aws ssm start-session --target i-0a1b2c3d4e5f67890"
```

---

## Pasul 5: Verificarea faptului că instanța s-a înregistrat în SSM

Se face **o singură dată**, după primul `apply`. Agentul SSM are nevoie de un minut sau două ca să se înregistreze.

```bash
aws ssm describe-instance-information \
  --query "InstanceInformationList[].{Id:InstanceId,Ping:PingStatus,Agent:AgentVersion}" \
  --output table
```

Trebuie să vezi instanța cu `PingStatus: Online`. Dacă lista este goală chiar și după câteva minute, repornește instanța din consola EC2 — agentul își cache-uiește credențialele și uneori are nevoie de un restart.

---

## Pasul 6: Conectarea la instanță

Aceasta este comanda de zi cu zi, echivalentul vechiului `ssh -i ...`. O rulezi de pe laptopul tău, oricând ai nevoie de un shell:

```bash
aws ssm start-session --target $(terraform output -raw instance_id)
```

Sau, dacă nu ești în directorul Terraform, cu ID-ul direct:

```bash
aws ssm start-session --target i-0a1b2c3d4e5f67890
```

Pe Windows PowerShell, unde `$(...)` funcționează diferit:

```powershell
aws ssm start-session --target (terraform output -raw instance_id)
```

Ieșirea din sesiune: `exit` sau `Ctrl-D`.

> Alternativă fără terminal: în consola AWS, **EC2 → Instances → selectează instanța → Connect → Session Manager → Connect**. Util pentru colegii care preferă browserul.

### Utilizatorul din sesiune

Sesiunea pornește ca utilizatorul **`ssm-user`**, nu `ec2-user`. Nu ești root și nu ești în home-ul lui `ec2-user`:

```bash
sudo su - ec2-user    # pentru mediul familiar ec2-user
sudo -i               # pentru root
```

`sudo` funcționează fără parolă. În CloudTrail sesiunea rămâne atribuită identității tale IAM individuale, chiar dacă la nivel de sistem operare toți apar ca `ssm-user`.

---

## Depanare

| Eroare | Cauză și rezolvare |
|---|---|
| `TargetNotConnected` | Agentul SSM nu este înregistrat. Verifică Pasul 5. Cauze frecvente: politica `AmazonSSMManagedInstanceCore` nu este atașată rolului instanței, sau regula de egress lipsește din Security Group. |
| `AccessDeniedException` la `StartSession` | Utilizatorul tău IAM nu este în `team_members`, sau instanța nu are tag-ul `Project`. Politica acordă acces **doar** instanțelor etichetate cu `Project = var.project_name`. |
| `InvalidInstanceId` | Regiune greșită. Adaugă `--region eu-central-1` sau rulează `aws configure set region eu-central-1`. |
| `SessionManagerPlugin is not found` | Pluginul nu este instalat sau nu este în `PATH`. Pe Windows: redeschide PowerShell. Pe macOS: `rehash`. |
| Sesiunea se închide singură | Timeout de inactivitate, setat la 20 de minute în `ssm-team-access.tf`. Normal. |

---

## Operațiuni utile

### Adăugarea unui coleg nou

1. Colegul își face `aws configure` cu propriile credențiale (Pasul 2) și instalează uneltele (Pasul 1).
2. Adaugi username-ul lui IAM în `team_members` din `terraform.tfvars`.
3. `terraform apply`.

Nu se generează și nu se trimite nicio cheie. Revocarea accesului: scoți numele din listă și rulezi `apply` din nou.

### Transferul de fișiere (înlocuitorul lui `scp`)

Session Manager nu oferă `scp` direct. Folosește bucket-ul S3 al proiectului, la care instanța are deja acces prin rolul ei IAM:

```bash
# de pe laptop, încarcă
aws s3 cp fisier.tar.gz s3://$(terraform output -raw s3_bucket_name)/

# în sesiunea SSM, descarcă
aws s3 cp s3://<nume-bucket>/fisier.tar.gz .
```

### Port forwarding (acces la un port local al instanței, fără a-l deschide în Security Group)

```bash
aws ssm start-session \
  --target $(terraform output -raw instance_id) \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8080"],"localPortNumber":["9090"]}'
```

Apoi deschizi `http://localhost:9090` în browser.

### Auditarea sesiunilor

Toate comenzile tastate în sesiuni sunt înregistrate în CloudWatch Logs, în grupul `/aws/ssm/<proiect>-sessions-dev`, cu retenție de 30 de zile.

---

## Credențiale pentru aplicație și GitHub Actions

> **Secțiunea veche a fost eliminată.** Comenzile `terraform output -raw iam_access_key_id` și `terraform output -raw iam_secret_access_key` **nu funcționează** — resursele `aws_iam_user` și `aws_iam_access_key` nu au fost niciodată declarate în cod, doar output-urile care le referențiau.

### Aplicația care rulează pe EC2 nu are nevoie de chei

Instanța primește credențiale automat prin rolul ei IAM (`aws_iam_instance_profile.app_profile`). SDK-ul AWS și AWS CLI le preiau singure din metadata instanței. Permisiunile deja atașate rolului:

- acces read/write la bucket-ul S3 al proiectului (`s3_app_policy`);
- citire din ECR (`AmazonEC2ContainerRegistryReadOnly`);
- Session Manager (`AmazonSSMManagedInstanceCore`).

Dacă aplicația are nevoie de permisiuni suplimentare, se adaugă o politică nouă la rol — **nu** se generează chei de acces.

### Pentru GitHub Actions

Varianta recomandată este **OIDC**: workflow-ul asumă un rol IAM printr-un token de scurtă durată, fără niciun secret stocat în GitHub. Necesită `aws_iam_openid_connect_provider` plus un rol cu o politică de trust pentru `token.actions.githubusercontent.com`.

Varianta cu utilizator IAM și chei de acces în GitHub Secrets funcționează, dar înseamnă credențiale de lungă durată care trebuie rotite manual. Dacă e nevoie de ea, se adaugă explicit în cod `aws_iam_user`, `aws_iam_access_key` și output-urile corespunzătoare (marcate `sensitive = true`).