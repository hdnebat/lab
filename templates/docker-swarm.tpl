---
- name: create docker swarm manager
  hosts: manager-first
  tasks:
  - name: "get docker info"
    shell: docker info
    register: docker_info
    changed_when: False
  - name: "create primary swarm manager"
    shell: docker swarm init --advertise-addr {{ ansible_default_ipv4.address }}
    when: "docker_info.stdout.find('Swarm: inactive') != -1"
  - name: "get docker swarm manager token"
    shell: docker swarm join-token -q manager
    register: manager_token
  - name: "get docker swarm worker token"
    shell: docker swarm join-token -q worker
    register: worker_token
  
- name: join docker swarm managers
  hosts: managers
  tasks:
  - name: "get docker info"
    shell: docker info
    register: docker_info
    changed_when: False
  - name: "join as a manager"
    shell: "docker swarm join --token {{ hostvars['${manager-1}']['manager_token']['stdout'] }} {{ hostvars['${manager-1}']['ansible_ens192']['ipv4']['address'] }}:2377"
    when: docker_info.stdout.find("Swarm{{':'}} inactive") != -1
    retries: 3
    delay: 20
  
- name: join docker swarm workers
  hosts: workers
  tasks:
  - name: "get docker info"
    shell: docker info
    register: docker_info
  - name: "join as a worker"
    shell: "docker swarm join --token {{ hostvars['${manager-1}']['worker_token']['stdout'] }} {{ hostvars['${manager-1}']['ansible_ens192']['ipv4']['address'] }}:2377"
    when: "docker_info.stdout.find('Swarm: inactive') != -1"
    retries: 3
    delay: 20