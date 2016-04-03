


gtar -cSzf freebsd.tar.gz disk.raw

gsutil cp freebsd.tar.gz gs://your-bucket

gcloud compute images create freebsd --source-uri gs://your-bucket/freebsd.tar.gz

gcloud compute instances create example-instance --machine-type f1-micro --image freebsd --zone europe-west1-c --boot-disk-size 10GB
