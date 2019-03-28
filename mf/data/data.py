#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import datetime
import requests
import json
import platform

from migasfree_sdk.api import ApiToken


def createDeploymentInternalMigasfreeClient( server, project, user="admin"):
    """
    Creates a repository named "migasfree client"
    """

    api = ApiToken(server=server, user=user)

    project_id = api.id("projects", {"name": project})

    # get migasfree client package id
    for package in api.filter("packages", {"project__id": project_id}):
        if "migasfree-client" in package["name"]:
            package_id = package["id"]
            break

    all_systems_id = api.id(
        "attributes",
        {"prefix": "SET", "value": "ALL SYSTEMS"}
    )

    today = datetime.datetime.now().strftime('%Y-%m-%d')



    # INTERNAL DEPLOYMENT migasfree-client
    data = {
        "name": "migasfree client",
        "packages_to_install": ["migasfree-client"],
        "start_date": today,
        "project": project_id,
        "included_attributes": [all_systems_id],
        "available_packages": [package_id]
    }

    deployment_id = api.post("deployments/internal-sources", data)

    if deployment_id:
        #print "deployment_id", deployment_id
        pass
    else:
        print """ERROR: creating internal deployment:
*******************************************************
Status: %s
Reason: %s
Content: %s
*******************************************************""" % (
    deployment_id.status_code,
    deployment_id.reason,
    "deployment_id._content")


def createDeploymenExternalBase(server, project, user="admin"):
    """
    Creates a repository named "BASE"
    """

    api = ApiToken(server=server, user=user)
    project_id = api.id("projects", {"name": project})
    all_systems_id = api.id(
        "attributes",
        {"prefix": "SET", "value": "ALL SYSTEMS"}
    )
    today = datetime.datetime.now().strftime('%Y-%m-%d')

    # EXTERNAL DEPLOYMENT
    data = {
        "name": "BASE",
        "frozen": True,
        "project": project_id,
        "included_attributes": [all_systems_id],
        "expire": 1440,
        "start_date": today
    }


    if project.startswith("debian"):
        data["base_url"] = " http://ftp.es.debian.org/debian"
        data["suite"] = project.split(":")[1]
        data["components"] = "main"
        data["options"] = "[arch=amd64]"
    elif project.startswith("ubuntu:"):
        data["base_url"] = "http://es.archive.ubuntu.com/ubuntu"
        data["suite"] = project.split(":")[1]
        data["components"] = "main universe multiverse"
        data["options"] = "[arch=amd64]"
    elif project.startswith("centos:"):
        data["base_url"] = "http://mirror.centos.org/centos"
        data["suite"] = project.split(":")[1]
        data["components"] = "os/x86_64 updates/x86_64 extras/x86_64"
        data["options"] = "gpgcheck=1 gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-$releasever"
    elif project.startswith("fedora:"):
        data["base_url"] = "http://download.fedoraproject.org/pub/fedora/linux/releases"
        data["suite"] = project.split(":")[1]
        data["components"] = "Everything/x86_64/os"
        data["options"] = "gpgcheck=1 gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch"
    elif project.startswith("opensuse"):
        data["base_url"] = "http://download.opensuse.org/distribution/leap"
        data["suite"] = project.split(":")[1]
        data["components"] = "repo/oss/suse"
        data["options"] = ""
    else:
        return

    deployment_id = api.post("deployments/external-sources", data)

    if deployment_id:
        #print "deployment_id", deployment_id
        pass
    else:
        print """ERROR: creating external deployment:
*******************************************************
Status: %s
Reason: %s
Content: %s
*******************************************************""" % (
    deployment_id.status_code,
    deployment_id.reason,
    "deployment_id._content")


def save_token(server, user, password):
    _ok_codes = [
        requests.codes.ok, requests.codes.created,
        requests.codes.moved, requests.codes.found,
        requests.codes.temporary_redirect, requests.codes.resume
    ]
    data = {'username': user, 'password': password}
    r = requests.post(
        '{0}://{1}/token-auth/'.format('http', server),
        headers={'content-type': 'application/json'},
        data=json.dumps(data),
        proxies={'http': '', 'https': ''}
    )
    if r.status_code in _ok_codes:
        _token_file = token_file(server, user)
        with open(_token_file, 'w') as handle:
            handle.write(r.json()['token'])


def token_file(server, user):
    list_server = server.split(":")
    server = "_{0}".format(list_server[0])
    if len(list_server) == 2:
        port = "_{0}".format(list_server[1])
    else:
        port = ""

    return os.path.join(
        get_user_path(),
        '.migasfree-token_{0}{1}{2}'.format(user, server, port)
    )


def get_user_path():
    _platform = platform.system()
    _env = 'HOME'
    if _platform == 'Windows':
        _env = 'USERPROFILE'
    return os.getenv(_env)


if __name__ == "__main__":

    user = "admin"
    password = "admin"
    server = os.environ["MIGASFREE_CLIENT_SERVER"]
    project = os.environ["MIGASFREE_CLIENT_PROJECT"]

    # save token file for user
    save_token(server, user, password)

    createDeploymentInternalMigasfreeClient(server, project, user)
    createDeploymenExternalBase(server,project,user)
