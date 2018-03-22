#!/usr/bin/env python
#
# I got this snippet freely available somewhere else and modified it to meet
# my needs.
# I suggest you to do the same.
#
import sys,os,requests

if len(sys.argv) > 2:
	giturl = "https://api.github.com/orgs/%s/repos?per_page=200"
	org = sys.argv[1]
	path = sys.argv[2]
	r = requests.get(giturl %(org))
	if r.status_code == 200:
		rdata = r.json()
	for repo in rdata:
		if os.path.exists(path + repo['name']):
			os.system("git -C " + path + repo['name'] + " pull -q")
		else:
			os.system("git -C " + path + " clone " + repo['ssh_url'] + ' -q')
else:
	print("Usage: %s organization directory" % (os.path.basename(__file__)))
