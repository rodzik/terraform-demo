[
  {
    "essential": true,
    "memory": 512,
    "name": "worker",
    "cpu": 2,
    "image": "${REPOSITORY_URL}:latest",
    "environment": [],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 3000
      },
      {
        "containerPort": 22,
        "hostPort": 22
      }
    ]
  }
]
