# PoC MongoDB Cluster
Proof-of-concept of a MongoDB development cluster on NodeJS.

## Step 1: Install Vagrant

Download Vagrant from https://www.vagrantup.com/downloads.html

If you are using Vagrant 1.8.0+ on Windows systems, you may have to fix an error
regarding rsync reported at https://github.com/mitchellh/vagrant/issues/6702 .
Edit
`$VAGRANT_HOME\embedded\gems\gems\vagrant-1.8.0\plugins\synced_folders\rsync\helper.rb`
and remove or comment out lines 77~79:

```
$ sed -n '77,79p' /cygdrive/c/HashiCorp/Vagrant/embedded/gems/gems/vagrant-1.8.1/plugins/synced_folders/rsync/helper.rb
          "-o ControlMaster=auto " +
          "-o ControlPath=#{controlpath} " +
          "-o ControlPersist=10m " +
```

## Step 2: Install rsync

Installation specifics can vary according to your OS/distribution. For Windows,
you'll usually want to do that via http://cygwin.com/install.html[Cygwin]. On
Linux, use your distribution's package manager (`apt-get`, `dnf`, `portage`,
etc.).

## Step 3: Download, setup and access the virtual machine

This one's easy. Simply run:

```
$ ls
LICENSE  poc_cluster  README.md  Vagrantfile

$ vagrant up
[...]

$ vagrant ssh
```

Vagrant will download the box file (if necessary), install additional software
and get everything ready.  After it's all done, run `vagrant ssh` as shown above
to gain access to the machine.

## Step 4: Run tests with the PoC

Once inside the VM, you can now use the
`/home/vagrant/poc_cluster/cluster_manage.sh` script to issue commands and
control a (by default) 3-node MongoDB cluster running on the local machine. You
can also use the `/home/vagrant/poc_cluster/nodejs/poc_cluster.js` application
to insert and query values inside a collection of said cluster.

### Cluster management

Use the `/home/vagrant/poc_cluster/cluster_manage.sh` script to manage the
MongoDB cluster. This script *MUST* be run as root. Use the following format to
call the script:

```
$ sudo bash ~/poc_cluster/cluster_manage.sh
Usage: /home/vagrant/poc_cluster/cluster_manage.sh (start|stop|port-start|port-stop|rs-conf|rs-status|query|status)
```

As shown, the script can take several parameters, explained below:

* `start`: start all (by default, 3) cluster nodes.
* `stop`: stop all (by default, 3) cluster nodes.
* `port-start`: start a cluster node listening on port `[PORT]`. `[PORT]` is a
  mandatory parameter. Port mappings are defined on the
`/home/vagrant/poc_cluster/etc/dirmaps.conf` file.
* `port-stop`: stop a cluster node listening on port `[PORT]`. This option
  is analogous to the `port-start` option, only in reverse.
* `rs-conf`: show current cluster configuration, querying the cluster node
  listening on `[PORT]`. `[PORT]` is a mandatory parameter.
* `rs-status`: show current cluster status, querying the cluster node listening
  on `[PORT]`. `[PORT]` is a mandatory parameter.
* `query`: show all documents on the `clustercol` collection (the default
  collection used on this PoC), querying the cluster node listening on `[PORT]`.
`[PORT]` is a mandatory parameter.
* `status`: show current cluster status as informed by `netstat`.

### Database operation

If any number of nodes of the cluster are operational (at least one node must
be running), you may use the `/home/vagrant/poc_cluster/nodejs/poc_cluster.js`
application to insert and query data inside the `clustercol` collection of the
`clusterdb` database.

Run:

```
$ node nodejs/poc_cluster.js
Connection established to
mongodb://localhost:27017,localhost:27018,localhost:27019/clusterdb?w=1&replicaSet=rs0&readPreference=secondaryPreferred

[1] Insert
[2] Query
[3] Exit

What do you wanna do? [1, 2, 3] :
```

Simply choose one of the options and follow the on-screen instructions to
operate the database.

Insertion example:

```
What do you wanna do? [1, 2, 3] :1
Type name to insert into collection: brasilia
Inserted NaN documents into the "users" collection. The documents inserted with
"_id" are: { result: { ok: 1, n: 1, opTime: { ts: [Object], t: 1 } },
  ops: [ { name: 'brasilia', _id: 573f8aefeeca5eae2332d222 } ],
  insertedCount: 1,
  insertedIds: [ 573f8aefeeca5eae2332d222 ] }
```

Query example:

```
What do you wanna do? [1, 2, 3] :2
Type string to query from collection: brasilia
Found: [ { _id: 573f8adcb406f19e226f88fb, name: 'brasilia' },
  { _id: 573f8aefeeca5eae2332d222, name: 'brasilia' } ]
```

### Test cases

Now that everything's up and running, you might wanna run a test or two to
make sure the MongoDB cluster is working reliably.

Test suggestions:

* *Write propagation*: use the `poc_cluster.js` NodeJS application to write a
  few entries to the database. Once that's done, use the `cluster_manage.sh`
script to query each individual node member and check if the data has been
copied to all nodes as expected.

* *High availability*: using the `cluster_manage.sh` script, stop one or two
  individual cluster nodes. Check if the `poc_cluster.js` NodeJS application can
still perform reads/writes as expected.

* *Node synchronization*: using the `cluster_manage.sh` script, stop one cluster
  node. After this is done, use the `poc_cluster.js` NodeJS application to write
several new entries to the database, which should be propagated among the
current members of the cluster. Afterwards, re-start the cluster node that was
stopped on the beginning of this test. Use the `query` option of the
`cluster_manage.sh` script to check if the new entries are correctly copied to
this node.

* *Node election:* there are two types of nodes inside a MongoDB cluster -- one
  PRIMARY node and possibly several SECONDARY nodes. Writes can _only_ be
performed to the PRIMARY node, while reads can be performed on any node of the
cluster. To test this capabilities, use the `rs-status` option of the
`cluster_manage.sh` script to find out the current PRIMARY node of the cluster.
Stop this node. After a few seconds, a new node should be elected, changing
status from SECONDARY to PRIMARY. Using the `poc_cluster.js` NodeJS application,
test if writes to the database work reliably both before the original PRIMARY
node goes down, during node election and after the new PRIMARY node assumes the
cluster.
