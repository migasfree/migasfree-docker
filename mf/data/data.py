#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import datetime

from api import MigasfreeApi


def createDeploymentMigasfreeClient(
    server, project,
    user="admin", password=""):
    """
    Creates a repository named "migasfree client"
    """

    api = MigasfreeApi(server=server, user=user, password=password)

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

    data = {
        "name": "migasfree client",
        "packages_to_install": ["migasfree-client"],
        "start_date": today,
        "project": project_id,
        "included_attributes": [all_systems_id],
        "available_packages": [package_id]
    }

    deployment_id = api.post("deployments", data)

    if deployment_id:
        #print "deployment_id", deployment_id
        pass
    else:
        print """ERROR: creating deployment:
*******************************************************
Status: %s
Reason: %s
Content: %s
*******************************************************""" % (
    deployment_id.status_code,
    deployment_id.reason,
    "deployment_id._content")

if __name__ == "__main__":

    user = "admin"
    password = "admin"
    server = os.environ["MIGASFREE_CLIENT_SERVER"]
    project = os.environ["MIGASFREE_CLIENT_PROJECT"]

    createDeploymentMigasfreeClient(server, project, user, password)
