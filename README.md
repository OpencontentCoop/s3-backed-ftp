# S3-Backed-FTP Server

An ftp/sftp server using s3fs to mount an external s3 bucket as ftp/sftp storage.

Started from [existing solution](http://cloudacademy.com/blog/s3-ftp-server/).

## Usage

To run:

1. Copy docker-compose.example.yml to docker-compose.yml and replace the variables used with your values
    - Add users to `USERS` environment variable. These should be listed in the form `username:hashedpassword`, each separated by a space.
     - Passwords for those users should be hashed. There are several ways to hash a user password. A common way is to execute a command like the following: `openssl passwd -crypt {your_password}`. Substitute `{your_password}` with the one you want to hash.
     - You may also use non-hashed passwords if storing passwords in plaintext is fine. To do this, change line ` echo $u | chpasswd -e ` => ` echo $u | chpasswd ` in the `users.sh` file (line #24).
    - Specify the S3 buckets were the files (`FTP_BUCKET`) and configs (`CONFIG_BUCKET`) will be stored.
    - If you are running this container inside an AWS EC2 Instance with an assigned IAM_ROLE, then specify its name in the `IAM_ROLE` environment variable.
    - If you do not have an IAM_ROLE attached to your EC2 Instance or wherever you are running this, then you have to specify the AWS credentials that will be used to access S3. These are the `AWS_ACCESS_KEY_ID` and the `AWS_SECRET_KEY_ID` keys.

2. If you have changed other files aside the `docker-compose.yml` file, then you have to build the docker container using:

    - `docker build --rm -t <docker/tag> path/to/dockerfile/folder`

3. Then after building the container (if necessary), run using:

    docker-compose up -d

   
## Environment Variables

| Variable | Required | Default value | Content
|----------|----------|---------------|----------
| `USERS`         | Yes |             | List of users to add to the ftp/sftp server. Listed in the form username:hashedpassword, each separated by a space.
| `FTP_BUCKET`    | Yes |             | S3 bucket where ftp/sftp users data will be stored.
| `CONFIG_BUCKET` | Yes |             | S3 bucket where the config data (env.list file) will be stored.
| `IAM_ROLE`      | No  |             |  name of role account linked to EC2 instance the container is running in.
| `TRACE`	  | No  | 0           | 1 to enable verbose options in bash scripts
| `MP_UMASK`      | No  | 0022        | option in s3fs
| `UMASK`         | No  | 0002        | option in s3fs, default is rwxrwxr-x

### Optional Environment Variables
These two environment variables only need to be set if there is no linked IAM role to the EC2 instance.

1. ` AWS_ACCESS_KEY_ID ` = IAM user account access key.
2. ` AWS_SECRET_ACCESS_KEY ` = IAM user account secret access key.
3. ` AWS_DEFAULT_REGION ` = bucket region

**Enjoy!**
