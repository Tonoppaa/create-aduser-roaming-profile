# create-aduser-roaming-profile
The first script allows user to create user info for ADUser (Active Directory User) and saves the created user info to a .txt-file. If the .txt-file is missing, the script will create a new file. The second script will:
  - Create a folder which will include roaming profile folders for ADUsers
  - Create a AD Organizational unit & AD Group for the AD Users (the AD Users are created later with this script; the user info is read from .txt-file)
  - Create a ADUser from the .txt-files' user info
  - Create a SMBShare for ADUsers just created
  - Add the roaming profile path for the ADUsers just created.
