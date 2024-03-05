# Rebuilding deepthtot with ProxMox

## Current State

There was a hard drive failure and during recovery all of the VMs were lost on the SAN.  They may be recoverable, but that's unknown at this time.

Regardless I've been wanting to switch to ProxMox for a long time now, so I'm going to do this.

Converting to ProxMox

1. Get the HP up and running on kvm slot 1.
2. Watch ProxMox videos
3. Install ProxMox on HP
4. Get familiar with ProxMox
1. Set up backups
5. Move ssd VMs onto HP
    1. Move Services
    2. Move IPA
    3. Move other stuff, whatever exists
1. After everything seems to be working um, bite the bullet, maybe
    1. Install proxmox on sandisk ssd
    2. Run it on old machine
    3. Try joining it to cluster
    4. Migrate a test machine to it from the HP
    5. Dump an image of the current drive onto the SAN
    1. Clone services, IPA, etc onto supermicro
    1. shut down the VMs on the HP and ensure the supermicro works
    1. bring the HP VMs back up
    1. stop the SM with ssd
    1. install proxmox onto the SM
    1. repeat the migrations etc
    1. test everything
    1. if there's a failure recover the image from the SAN
5. Get Plex working
7. Get torrent working/rebuild torrent
6. Get Mastodon Working
8. Get Mail Server Ready
9. Create the dmz machines
1. Basic system is configured
    1. K8S
    1. DNS
    1. CertMonger
    1. S3 server
    1. gitlab
    1. migrate mail and mastodon to k8s

## ProxMox notes

ProxMox is really cool, I mean really.  It basically serves the same purpose as vsphere except it's all open source and brodcom can kiss my fat transgender ass.  This is why you never, ever trust closed source for anything useful.  (do you hear that plex???)

Anyway, this is what I've done, I watched [LearnLinuxTV's proxmox course on youtube](https://www.youtube.com/watch?v=5j0Zb6x_hOk&list=PLT98CRl2KxKHnlbYhtABg6cF50bYa8Ulo) It's pretty good, a little slow and repetitive, but it gave me a really good feel for how to proxmox.  I've been kinda working along with it to do my actual server.

The server is my old HP proliant, it has a 4 x AMD A12-9800 RADEON R7, 12 COMPUTE CORES 4C+8G, I'm not sure what that means, if it has 12 compute cores how is there only 4 cores?  Regardless, it's big enough for my purposes.  What my purposes are is set this thing up to be the minimal system, what is still surviving namely, services, ipa, awx, backup/and it looks like plex?

The system came up just peachy, I'm loving it.  I need to get into the habit of creating template disks, in fact I'll probably use ansible for it.  The idea is to have a 'golden' image, yeah, I know I always said that wasn't a good idea, however without a fast package cache (when let's face it, nexus is most certainly not) installing a system from bare metal is just too friggin slow.  That said, I think a big part of it is how slow my san is, that needs to be addressed, but when I have money.

I'm thinking it may be good to put an ssd on my main server and build the VMs there then migrate them to another drive.  Yes, I can do this with proxmox, it doesn't have all of ESXi's stupid money grubbing limitations.

So, as I was saying, after getting the proliant to boot, which was a very frustrating day followed by getting it done almost immediately the next day.  Installing proxmox was really easy, it probably doesn't need explanation, however basically you transfer it to a thumb drive (I had to track down software to do this, but I've forgotten what it was and don't feel like looking it up now), then booting the thumb drive, and use that to do the install, which as I said was super straight forward.

After that I started kicking the tires, I watched the aformentioned video series and worked along with it.  Create a VM, turn it into a template, spin up several more and that's it.

Now, one caveat, I really don't like how Jay's method of preparing a machine works.  When it comes time, this is what I want:

Using cloud-init, the machine's name should be available in a variable.  Use that, then get cloud-init to be set up to do it's whole thing on the next boot.  I think that just consists of blowing away everything (ssh keys, logs, machine-id, etc) and finally erasing a file that causes cloudinit to run.  I think that may be a u 13.10 thing though, I'm not finding it on my current machines.

TODO: Figure out how Ubuntu 22.04 and earlier cause cloud-init to only run completely on the first boot.

I need to know more about cloud init, it's the missing piece of cleanly bringing up a new vm autonomously.  Fabulous!  I've always wanted something like it.

This has gone on too long... My plan for today is:

1. Sometime during the day rsync hg2t2g volume1 to the external drives.  It'll probably take longer than a day, if that's the case play wow until it's done :-)
1. Move the VMs.  [docs](https://pve.proxmox.com/wiki/Migrate_to_Proxmox_VE) use ovftool on esx and qm importovf on pve.<br>
NOTE: a side note, it would be cool to have the proxmox machine id = the last tuple of the address
1. Do it again because I know I'll learn stuff while doing it the first time.<br>
NOTE: there's a cloud-init disk in the system, that may be useful for this.
1. If everything seems to be working, shut down the original machines and bring the new ones on-line.<br>
NOTE: track down how pve is defined, clearly it's from the last install see what it is and make the HP be pve.
1. Let it run overnight

Tomorrow:

1. Back up the old machine
1. Install proxmox on heartogold.  Maybe onto the sandisk if I'm squeemish.
1. Join it with the HP
1. Migrate the machines to it.

NOTE: yeah, I definately should do a dry run with the USBSSD I have.

Well, I fell into the youtube black hole... I'm trying to rememver who I saw with the command that allows you to take standard images and add packages to them.  (like emacs and ipa-client)
Still having issues.  I can't seem to find the application I ran across yesterday to add deb packages to an img file...  waste of time.

I've been unable to transfer IPA to proxmox, it just doesn't work.  The test machine worked fine, I'm suspecting it's the centos instead of ubuntu.  I'm ls

2/15/2 today I got services over.  IPA is a problem, I don't know if it's centos related or joy related.  Moving services involved editing /etc/netplan/01-network-manager-all.yaml which has the fixed ID and ethernet device in it.  I'm hoping this is because it has a fixed IP.  Which reminds me *always* use DHCP to assign addresses.  Use a MAC if you want static assignments.

2/18/24 I've been remiss of keeping this stuff updated, what I should do is write everyting down as I do it and then edit it down.
anyway...  


### transferring a debian VM from esxi to pve
1. ssh into the pve machine
1. If you haven't downloaded ovftool do so now, it's easy to find with google, who knows if broadcom will keep it working or not.
1. run ./ovftool vi://<ESXi server>/<machine name>
    * On deepthot the ESXi is 192.168.42.3.  1=router 2=dns/dhcp 3=hypervisor 4=DNS/certs/LDAP/kerberos aka AD or IPA
1. qm importovf ASSET# <path to ovf file> <store to create machine on>  (right now that would be local-lvm and h2gt2g-hosts)
1. add a nic to the machine
1. boot it up, get root and: rm cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
1. reboot
1. I'm sparked
1. if it's joined to the network go into ipa and change the a record to match what the machine is now

Now, this is on 20.04.  I'm hoping 22.04 didn't have the issue where the cloud config file needed removing.  I know this didn't happen while I was running services.

### transferring a centos 7 vm from esxi to pve
Not nearly as clean, when I tried the ovftool the imported machine just sucked.  Fortunately

1. get a copy of rescuzilla [download](https://github.com/rescuezilla/rescuezilla/releases/download/2.4.2/rescuezilla-2.4.2-64bit.jammy.iso)
1. boot the machine you want to transfer with it
1. clone the drive actually the vm
1. boot the machine you want to move it to with rescuezilla
1. install the clone
1. reboot and it works

The A record may be wrong sometimes when the machine comes up.  Just put the new ip into the a record in ipa.

## awx
Awx almost worked when I transferred it.  The main problem was it had a different ethernet address which didn't work with the dns stuff used by IPA.  So, I changed DNS entry by hand and now it's cool.

Testing to make sure it works:
1. --spin up an image on proxmox--
2. --edit the hosts.ini file to add it--
1. --try running the playbook locally--
1. repeat the above except using awx

wow, that took awhile, but the local ansible runner once I got it running worked flawlessly.  AWX is more problematical.

It's taking me awhile to get awx to run a new inventory.  I don't want to do the old one because of so many machines, I just want one that's clean.  Unfortunately I don't think I know or rather remember how to make a new inventory and use it on an arbitrary system running an arbitrary job.  awx. is, as always confusing as fuck to me.  Actually, not too bad if you do it by hand.  AWX...  probably more trouble than it's worth for something I'm only doing once.

I've got the proxmox backup server (pbs) installed, it was pretty straight forward since it's almost like proxmox.  The only thing that confused me is that 'backing store' means where the place you want to do your backups is mounted.  Right now that's h2gt2g which is kinda useless.  but I've mounted in the fstab 192.168.42.7:/volume1/pbs to /mnt/h2gt2g  

So for today I'm going to migrate the blueray machine, and I think that's all.  Then I'm going to install proxmox to the ssd thumbdrive I have and try to boot it.  I'm not quite ready to overwrite esxi, scary, you know?

Oh, I also got backups set up for the vms.  we'll see how other vms handle it when they've got more on them than services and ipa.

I fell down the vlan rabbit hole.  This is a big project and I need to stop dwelling on it....

So, 'blueray' the machine that has the blueray and all of the usb backup drives on it has been difficult.  To the best of my knowledge qm doesn't like btrfs disks.  That machine was made when I still thought btrfs was a good idea.  (It is, but it isn't tolerant of losing power.  I've had several die, that was how I lost my first k8s nodes and all the cool stuff I had set up in 2019)  Anyway, to import it I did this:

1. create a ext4 disk with a boot partition and an lvm partition with one drive full
1. mount it on /mnt and the boot on /mnt/boot
1. rsync -xHAXavS / /mnt
1. mount -obind /proc /mnt/proc
1. repeat the previous for /dev, /sys. 
1. run lvmetad
1. chroot /mnt
1. I think grub install /dev/sdc or whatever the drive is.  I had to futz around a bit so it might not be that, it might be apt install --reinstall 'the current kernel package' or dpkg-reconfigure grub-pc.  One of those got it done.
1. use rescuezilla to make an image of the new drive
1. make a drive on proxmox of the same size
1. boot the proxmox machine with rescuezilla
1. restore the image above to the new drive

Note to self: one of the main things that was keeping me from working yesterday is the machine blueray had 8 cores.  It's only powered up when it's doing things like ripping dvds or backing up onto the external drives.

That's where I am now.  What I'm going to do next is to snapshot the machine.  Boot it and see if it's working.  It won't work completely because it's now running on the hp where the usb drives are not.  I may have to boot it in rescue mode and edit /etc/fstab to remove the usb drives.  Anyway, see if it boots.  When it does, install qemu-guest-agent, take another snapshot.  Then upgrade the ubuntu to 22.04, might have to do 20.04 first.  It's on 18.04 which is unsupported nowadays.

Oy vey... I'm getting a lot of grief from cloud-init, I think I better learn it.  Anyway, blueray is doneish.  It will need to be reconfigured after it is placed on the supermicro.

## Installing proxmox on supermicro

The next step is to install proxmox on the supermicro.  Just because I'm paranoid I'm going to configure proxmox on sandisk thumb ssd.  Create some machines, move them back and forth etc.  When the final move happens this should be a copy rather than a move.  If everything works the next thing is to install proxmox on the supermicro for real.

This will involve creating a cluster on proxmox, joining the supermicro to it, play with it, unjoin it, then do the install and the final join.

Well...  As soon as proxmox started to boot it said there was a firmware bug in the processor and it needed a firmware patch.  Then it stopped booting, and now it won't boot at all anymore.  I'm glad I made sure everything was off of it.  So....  total failure at the moment, I'll try to get the machine back.

## Investigating pxe boot provisioning machines all the way to configuration.

Since I'm on the old game machine I can't really do any k8s or plex at the moment.  Instead I'm going to play with images and investigate pixe booting with the machine catching it and configuring it the rest of the way with ansible.

What I did was install netboot.xyz.  It's a wonderful little tftp server, you boot it and then it has a huge list of bootable CDs.  Install disks for every linux under the sun, rescue disks, everything.  This would be fantastic when I'm trying to recover a machine where I have to track down the rescue disk and burn it, then boot the machine.  Fah...  Now any machine on the network I just pxeboot it and all the media you want is there.

But I've not got it working to configuration yet.  What I need at this point is for awx to be able to see the newly booted machine.  I've got this great script that makes groups for everything.  I've been unable to convince awx to use it as a dynamic inventory, but it works great on ansible-playbook from the cli.  Still investigating.

## New machine arrived.
It's wonderfuly, kinda short on drive space, but that just means it's the same size as the san.  I'm trying to figure out how to partition it.  It does have two SSDs, but they're not the same size so they can't be raided.

The old machine is still dead, although I haven't tried it in awhile.  I'm planning on opening it up and figuring how how to reset it, removing the cmos battery for a long while might do the trick.

I spent many hours trying to get proxmox on it.  I finally gave up on uefi and did a bios boot on it.  That worked, from the thumb drive.  I'm not sure if the PXI boot would work now that I understand.

Anyway, proxmox is up and running.  I've named it eddie (the shipboard computer).

## Migrating machines to eddie
Oh the hp is called pve, which is the default.  I'm hoping heartogold will come back.  But henceforward I'll call the machines by their names.

Currently h2gt2g is up and running, but the vms are all on pve's local disk.  So, the next step is

1. [x] Migrate the hard drives from pve to h2gt2g
1. [x]Migrate the machines to eddie
1. [x]Migrate the hard drives to eddie's boot disk

## Pihole
I installed pihole on a really too big for it VM.  I should probably use debian for it.  Anyway, the only issue was it wants to have
port 53, and systemd_resolver of course has it up.  When you take it down obviously resolv.conf goes away.

So, delete resolve.conf and insert the following:

'''
nameserver 127.0.0.1
options edns0 trust-ad
search deepthot.aa deepthot
'''

Came up cleanly, the best place to get blacklists is:  https://firebog.net it has a ton of lists of varying qualities.

## k3s 

The only distrobution that I've been successful with is centos stream 8 generic cloud.
The machine should be at least 4gb ram, 2 cores, and 23gb disk.

It takes forever to set up wait for the dns name to appear.
sheesh it's *always* selinux.  disable it and reboot.

K3s is really easy to set up.  
```bash
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=644 sh - 
```

curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=644 sh -

This installs k3s.  The environment variable sets the kubeconfig to readable so the kubectl can simply be run on the machine.

This is really fugly I'm hoping to find a better way.  k3s includes a load balancer which interacts poorly with metallb.  So you need to hack the service file.

```sh
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.6+k3s2 K3S_KUBECONFIG_MODE=644 sh - 
sudo sed -i '/server/s/r /r --disable servicelb /' /etc/systemd/system/k3s.service
sudo systemctl daemon-reload && sudo systemctl restart k3s
```
ToDo: find a way to set this in a config file or env variable

Before you can do pretty much anything you need a way to create ips for ingresses into the system.  I usually choose metallb since it's really simple and works great.  You simply 

```yaml
cat >metal.yaml <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.42.200-192.168.42.209
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: deepthot
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool

EOF

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl wait deployment controller -n metallb-system --for condition=Available=True --timeout=120s 
kubectl apply -f metal.yaml
```
Now you have k3s cluster.  This is a single node cluster with both controlplane and workers.  

ToDo: document how to do separate worker nodes and set up HA.


## get new awx up

The next thing to do is to bring up AWX.  The best way I've found is using [kurokobo's](https://github.com/kurokobo/awx-on-k3s) configuration.  I haven't looked in detail to see if there's an easier way, but this one works.  However it only works with rpm distros, rocky, fedora, etc

From their README:

Ensure curl and git are installed `sudo apt install git curl -y` or whatever your distro wants.

Clone the repository to install from:
```sh
cd ~
git clone https://github.com/kurokobo/awx-on-k3s.git
cd awx-on-k3s
git checkout 2.12.1
```

Deploy the operator by `kubectl apply -k operator`

Wait for the deployment to finish`kubectl wait deployment awx-operator-controller-manager  -n awx --for condition=Available=True --timeout=300s`

Edit the configuration:

```
AWX_HOST="$MY_HOST"
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out ./base/tls.crt -keyout ./base/tls.key -subj "/CN=${AWX_HOST}/O=${AWX_HOST}" -addext "subjectAltName = DNS:${AWX_HOST}"
```

Modify hostname in base/awx.yaml.
```
sed -i "s/awx.example.com/$AWX_HOST/" base/awx.yaml
```
For instance:
```
...
spec:
  ...
  ingress_type: ingress
  ingress_hosts:
    - hostname: awx.example.com     👈👈👈
      tls_secret: awx-secret-tls
...
```

IMPORTANT: This is the hostname of ingress, not the host.


Modify two passwords in base/kustomization.yaml. Note that the password under awx-postgres-configuration should not contain single or double quotes (', ") or backslashes (\) to avoid any issues during deployment, backup or restoration.

...
  - name: awx-postgres-configuration
    type: Opaque
    literals:
      - host=awx-postgres-13
      - port=5432
      - database=awx
      - username=awx
      - password=Ansible123!     👈👈👈
      - type=managed

  - name: awx-admin-password
    type: Opaque
    literals:
      - password=Ansible123!     👈👈👈
...

If you want to have persistent volumes on the local machine do something like:

```bash
sudo mkdir -p /data/postgres-13
sudo mkdir -p /data/projects
sudo chmod 755 /data/postgres-13
sudo chown 1000:0 /data/projects
```
Real storage TBD

Now deploy it:

`kubectl apply -k base`

`watch kubectl -n awx get awx,all,ingress,secrets` is nice to watch the progress.

and `kubectl -n awx logs -f deployments/awx-operator-controller-manager` is good for watching what's going on.

This takes a *long* time.  Go off and do something.



https://www.apalrd.net/posts/2023/pve_cloud/ has a great little script that installs images for some of the more popular operating systems and then makes them into a template.  

I'm having a ton of grief installing rocky 9.  It took for friggin ever on the big machine.  I think it's *really* friggen slow.  Not entirely sure why.

I'm using https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/kind-install.html for the awx install.  I may end up just saying eff it and install this:  https://youtu.be/UoOcLXfa8EU?si=SdiHY-Ir2ZUBzwFZ  then deploy awx with https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/helm-install-on-existing-cluster.html

Days into it here, but https://techviewleo.com/install-kubernetes-cluster-using-k3s-on-debian/ has a really concise description on how to install k3s

I think I've got a good one for installing awx as well, but I believe I must have metallb installed.  (fun, I loved it last time I had k8s up)


AWX install, following https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/basic-install.html and
https://github.com/kurokobo/awx-on-k3s.git

ToDo: here are the things I want to do.  I'm putting them here to keep from getting distracted from them.
1. rancher
1. auto certs
1. truNAS
1. zfs
1. cloudflare
1. k8s
1. plex
1. mastodon
1. other fediverse things
1. vscode clean this up
1. zsh
1. ~~awx getting proxmox inventory~~
1. ~~pxe server (look at maas and the other thing tt mentioned) (tt is technotim on youtube for future joy)~~
1. gitlab
1. figure out why some vms are not getting dns name correctly.  Hypothosis trick is not to release the leases on reboot.
1. vlans
1. move from deepthot.aa to local.deepthot.org or maybe l 'cause it's getting pretty long'
1. move services to a stand alone raspberry pi
