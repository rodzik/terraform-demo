[
  {
    "essential": true,
    "memory": 512,
    "name": "worker",
    "cpu": 2,
    "image": "${REPOSITORY_URL}:latest",
    "portMappings": [
      {
        "containerPort": 3000
      }
    ],
    "environment": [
      {"name": "RAILS_ENV", "value": "production"},
      {"name": "RDS_DB_NAME", "value": "${RDS_DB_NAME}"},
      {"name": "RDS_USERNAME", "value": "${RDS_USERNAME}"},
      {"name": "RDS_PASSWORD", "value": "${RDS_PASSWORD}"},
      {"name": "RDS_HOSTNAME", "value": "${RDS_HOSTNAME}"},
      {"name": "RDS_PORT", "value": "${RDS_PORT}"},
      {"name": "RDS_URL", "value": "${RDS_URL}"}
    ]
  }
]
