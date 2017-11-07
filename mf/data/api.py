#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import requests
import json
import os


class MigasfreeApi():
    _ok_codes = [
        requests.codes.ok, requests.codes.created,
        requests.codes.moved, requests.codes.found,
        requests.codes.temporary_redirect, requests.codes.resume
    ]
    server = ""
    headers = {"content-type": "application/json"}
    protocol = "http"
    proxies = {'http': "", "https": ""}
    version = 1
    token_file = ""

    def __init__(self, server, token="", version=1, user="admin", password=""):

        self.server = server
        self.version = version

        if token == "":
            self.token_file = os.path.join(os.path.expanduser('~'),
                ".migasfree-token.%s" % user)
            if os.path.exists(self.token_file):  # get token by file
                _file = open(self.token_file, 'r')
                self.token = _file.read()
                _file.close()
            else:  # get token by ayth

                if password == "":
                    password = raw_input("Please enter %s password: " % user)

                url = '%s://%s/token-auth/' % (self.protocol, self.server)
                r = requests.post(
                    url=url,
                    headers={"content-type": "application/json"},
                    data=json.dumps({"username": user, "password": password}),
                    proxies=self.proxies)
                if r.status_code in self._ok_codes:
                    self.token = r.json()["token"]
                    _file = open(self.token_file, 'w')
                    _file.write(self.token)
                    _file.close()
                else:
                    raise Exception('Not auth')

        self.set_token(self.token)

    def set_token(self, token):
        self.headers['authorization'] = "Token %s" % token

    def url(self, endpoint):
        return "%s://%s/api/v%s/token/%s/" % \
            (self.protocol, self.server, self.version, endpoint)

    def url_id(self, endpoint, id):
        return "%s%s/" % (self.url(endpoint), id)

    def paginate(self, endpoint, params={}):  # GET
        return requests.get(
            self.url(endpoint),
            headers=self.headers,
            params=params,
            proxies=self.proxies
        ).json()

    def post(self, endpoint, data):  # POST
        return requests.post(
            self.url(endpoint),
            headers=self.headers,
            data=json.dumps(data),
            proxies=self.proxies
        )

    def delete(self, endpoint, id):  # DELETE ID
        return requests.delete(
            self.url_id(endpoint, id),
            headers=self.headers,
            proxies=self.proxies
        )

    def patch(self, endpoint, id, data):  # PATCH ID
        return requests.patch(
            self.url_id(endpoint, id),
            headers=self.headers,
            data=json.dumps(data),
            proxies=self.proxies
        )

    def put(self, endpoint, id, data):  # PUT ID
        return requests.put(
            self.url_id(endpoint, id),
            headers=self.headers,
            data=json.dumps(data),
            proxies=self.proxies
        )

    def get(self, endpoint, param):
        """
        param can be 'id' or '{}'
        return only one object or exception
        """
        if isinstance(param, (long, int)):  # GET ID
            r = requests.get(
                self.url_id(endpoint, param),
                headers=self.headers,
                params={},
                proxies=self.proxies
            )
            if r.status_code in self._ok_codes:
                return r.json()
            else:
                raise Exception('Status code %s' % r.status_code)
        else:
            r = requests.get(
                self.url(endpoint),
                headers=self.headers,
                params=param,
                proxies=self.proxies
            )
            if r.status_code in self._ok_codes:
                data = r.json()
                if data["count"] == 1:
                    return data["results"][0]
                elif data["count"] == 0:
                    raise Exception('Not found')
                else:
                    raise Exception('Multiple records found')
            else:
                raise Exception('Status code %s' % r.status_code)

    def filter(self, endpoint, params={}):  # iterator
        url = self.url(endpoint)
        while url:
            r = requests.get(
                url,
                headers=self.headers,
                params=params,
                proxies=self.proxies
            )
            if r.status_code in self._ok_codes:
                data = r.json()
                for element in data["results"]:
                    yield element
                url = data["next"]

    def id(self, endpoint, params):
        return self.get(endpoint, params)['id']
