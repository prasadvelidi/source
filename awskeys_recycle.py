#!/bin/python

from boto import iam
from datetime import datetime
import sys

# color codings used in the html report
hcol = "#95A5A5"
dcol = "#F5B7B1"
wcol = "#FFFFFF"

# connecting to a region
conn=iam.connect_to_region('eu-west-1')

# fetching all the users
user_list=conn.get_all_users()
list1=user_list['list_users_response']['list_users_result']['users']

# construct the html body and table header to show the results
html = "<html><table border='1' frames='border' rules='all' cellpadding='4px'>"
html = html + "<tr bgcolor='#95A5A5'><th colspan='9'>AWS ACCESS KEY REPORT</th></tr>"
html = html + "<tr bgcolor='#95A5A5'><th>Sno</th><th>AWS USER</th><th>ACCESS KEY</th><th>STATUS</th><th>CREATION DATE</th><th>REMARKS</th>"

count=0
for i in list1:
                user=i['user_name']

		# fetching all the IAM access keys
                access=conn.get_all_access_keys(user)
                if len(access['list_access_keys_response']['list_access_keys_result']['access_key_metadata']) != 0 and len(user) == 4:
                        for j in range(0,len(access['list_access_keys_response']['list_access_keys_result']['access_key_metadata'])):
				mesg=""
				count=count+1

                                access_key_id=(access['list_access_keys_response']['list_access_keys_result']['access_key_metadata'][j]['access_key_id'])

                                # fetching the Access key creation date
                                key_creation_date=(access['list_access_keys_response']['list_access_keys_result']['access_key_metadata'][j]['create_date']).split("T")[0]

                                # fetching the Todays date
                                now = datetime.now()
                                current=now.strftime('%Y-%m-%d')

                                date_format = "%Y-%m-%d"
                                key_date = datetime.strptime(key_creation_date, date_format)
                                current_date = datetime.strptime(current, date_format)

                                # calculating the password age
                                password_age=current_date-key_date

				# calculating the access key created age
                                if password_age.days > 45:
                                    col = dcol
                                    mesg="older_than_45_days"
                                    # conn.update_access_key(access_key_id,"Inactive",user)
                                else:
                                    col = wcol
                                    mesg="within_threshold_45_days"

                                access=conn.get_all_access_keys(user)
                                status=(access['list_access_keys_response']['list_access_keys_result']['access_key_metadata'][j]['status'])
                                html = html + "<tr bgcolor='%s'>" % col + "<th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th>" % (count, access_key_id, status, key_creation_date, mesg, user) + "</tr>"
                else:
                        print "INFO:ACCESS KEY not enabled for user: %s" % user

# add the closing tags for html content in the end
html = html + "</table></html>"

# write to a report.html so that we can mail the group
f = open("report.html", "w")
f.write(html)
f.close()
