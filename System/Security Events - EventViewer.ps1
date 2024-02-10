cls
Get-EventLog -LogName System -After "2019-01-01" | Where-Object {($_.EventID -in (529,530,532,533,534,535,539,675,644,4663,4724,4704,4717,4719,4739,1102))}




<#
Event ID: 529

This event record indicates an attempt to log on using an unknown user account or a valid user account but with an incorrect password. An unexpected increase in the number of these audits could represent an attempt by someone to find user accounts and passwords (such as a "dictionary" attack, in which a list of words is used by a program to attempt entry

Event ID: 530

The user account and password are correct, but the logon attempt failed because it occurred outside the hours that the user is allowed to log on. This restriction is configured on the user's domain account.

Event ID: 531

The logon attempt failed because the user account used to log on is currently disabled. This restriction is configured on the user account on the local computer or on the domain.

Event ID: 532

The logon attempt failed because the user account has expired. This restriction is configured on the user's account on the local computer or on the domain.

Event ID: 533

The logon attempt failed. The user account used to log on is not permitted to log on from this computer. This restriction is configured on the user's domain account.

Event ID: 534

This event record indicates that an attempt was made to log on, but the local security policy of the computer does not allow the user to log on in the requested fashion (such as interactively).

Event ID: 535

The logon attempt failed because the user account password that was used to log on has expired. This restriction is configured on the user account on the local computer or on the domain.

Event ID: 539

A user tried to log on to the system using an account that is locked out. A large number of these events logged in Event Viewer usually indicate that a service account password is configured incorrectly or a program password does not match the password on the server. This might be caused by a password-guessing attack against an account that has account lock out enabled, but this is highly unusual.

Event ID: 675

The ticket-granting ticket (TGT) was not obtained. The reason is in the failure code, which is a translation of the RFC 1510 Kerberos error code.

This event record indicates that an authentication ticket has been granted. There is no Failure Audit form of this audit event record.

Event ID: 644

A user account was locked out. An account is locked out when a specified number of unsuccessful logon attempts occur over a specified time period.

Unsuccessful logon attempts might indicate that the user forgot the password. However, they can also indicate password guessing by an unauthorized user or a denial of service attack against your network.

The account can be locked out for a set time period or until an administrator manually unlocks it.


EVENT 4663 – This one is generated when you have a high number of files being deleted. Chances are it’s innocent. It can also be someone who is dumping crucial information and wants to make life difficult for you and/or the company.

EVENT 4724 – Password reset. Again, probably innocent enough. But then it depends on the account having the password reset. Resetting service account passwords is a nice way for an upset sysadmin to spread havoc through the infrastructure.

EVENT 4704 & 4717 – Changes to user rights assignments. Normally we’d expect to see this associated with a ticket request. However, if someone is planning something underhanded, there’s a really good chance they won’t follow protocol to do it. An event like this will often tell you what rights were assigned to a user or account, but it probably won’t tell you who did it. This is one to watch for because a hacker on the inside might try to elevate a service account or an ordinary user account with permissions that will give them access to the system and help them cover their tracks doing it.

EVENT 4719 & 4739 – If you see these, start thinking someone has altered the Audit and Account policies in the system. Often a good prelude to an internal hack.

EVENT 1102 – This is often a big one to watch for and can be a really big smoking gun. This means that someone has just cleared the security log. Again, this can be innocent, but it can also mean someone is trying to cover his tracks. This is a good tripwire that could easily mean that an attack on the network is coming, or it’s already winding down.
#>