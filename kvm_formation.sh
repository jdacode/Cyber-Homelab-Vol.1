#!/bin/bash

wanna_continue()
{
    action1=$1
    action2=$2
    # echo $action1
    # echo $action2
    echo -e "\e[31m\nWant to continue (y/n[default]): \c \e[0m"
    read  answer
    # echo "The word you entered is: $answer"
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        $action1
    else
        $action2
    fi
}

change_libvirtd_file() {
    # Uncomment line
    sudo sed -i "/unix_sock_group =/ s/# *//" /etc/libvirt/libvirtd.conf
    sudo sed -i "/unix_sock_rw_perms =/ s/# *//" /etc/libvirt/libvirtd.conf
    # Comment line
    # sudo sed -i "/unix_sock_group =/ s/^/# /" /etc/libvirt/libvirtd.conf
    # sudo sed -i "/unix_sock_rw_perms =/ s/^/# /" /etc/libvirt/libvirtd.conf
    sudo cat /etc/libvirt/libvirtd.conf | grep unix_sock_group
    sudo cat /etc/libvirt/libvirtd.conf | grep unix_sock_rw_perms
}

start_enable_libvirtd() {
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
    systemctl status libvirtd
}

add_to_group() {
    sudo usermod -a -G libvirt $(whoami)
    getent group libvirt
}

config_libvirt()
{    
    echo -e "\nBefore: \n"
    sudo ls -hals /etc/libvirt/libvirt.conf
    ls -hals ~/.config/libvirt/
    cat ~/.config/libvirt/libvirt.conf | grep uri_default
    sudo cp -v /etc/libvirt/libvirt.conf ~/.config/libvirt/    
    sudo chown $(whoami):$(whoami)  ~/.config/libvirt/libvirt.conf    
    # Uncomment line
    sudo sed -i "/uri_default =/ s/# *//" ~/.config/libvirt/libvirt.conf
    # Comment line
    # sudo sed -i "/uri_default =/ s/^/# /" ~/.config/libvirt/libvirt.conf
    echo -e "\nAfter: \n"
    sudo ls -hals /etc/libvirt/libvirt.conf
    sudo ls -hals ~/.config/libvirt/
    sudo cat ~/.config/libvirt/libvirt.conf | grep uri_default
}

virsh_status() {
    virsh list --all
    virsh pool-list 
}

groupinfo_virtualization() {
    echo -e "\e[31m\n\n>\t dnf groupinfo virtualization:\e[0m\n"
    dnf groupinfo virtualization
    echo -e "\e[31m\n\n>\t dnf list installed \"virt-install\":\e[0m\n"
    dnf list installed "virt-install"
    echo -e "\e[31m\n\n>\t dnf list installed \"libvirt-daemon-config-network\":\e[0m\n"
    dnf list installed "libvirt-daemon-config-network"
    echo -e "\e[31m\n\n>\t dnf list installed \"libvirt-daemon-kvm\":\e[0m\n"
    dnf list installed "libvirt-daemon-kvm"
    echo -e "\e[31m\n\n>\t dnf list installed \"qemu-kvm\":\e[0m\n"
    dnf list installed "qemu-kvm"
    echo -e "\e[31m\n\n>\t dnf list installed \"virt-manager\":\e[0m\n"
    dnf list installed "virt-manager"
    echo -e "\e[31m\n\n>\t dnf list installed \"virt-viewer\":\e[0m\n"
    dnf list installed "virt-viewer"
    echo -e "\e[31m\n\n>\t dnf list installed \"libguestfs-tools\":\e[0m\n"
    dnf list installed "libguestfs-tools"
    echo -e "\e[31m\n\n>\t dnf list installed \"python3-libguestfs\":\e[0m\n"
    dnf list installed "python3-libguestfs"
    echo -e "\e[31m\n\n>\t dnf list installed \"virt-top\":\e[0m\n"
    dnf list installed "virt-top"
}


install_virtualization() {
    echo -e "\e[31m\n\n>\t Your system supports virtualization?:\e[0m\n"
    LC_ALL=C lscpu | grep Virtualization
    wanna_continue return formation_init
    groupinfo_virtualization
    echo -e "\e[31m\n\n>\t Do you want to update your system first? sudo dnf update?:\e[0m\n"
    wanna_continue "sudo dnf update" return
    echo -e "\e[31m\n\n>\t Do you want to install the mandatory, default, and optional packages? sudo dnf group install --with-optional virtualizatio?:\e[0m\n"
    wanna_continue "sudo dnf group install --with-optional virtualization" return
    echo -e "\e[31m\n\n>\t Verifing that the KVM kernel modules are properly loaded: systemctl status libvirtd \e[0m\n"
    systemctl status libvirtd
    echo -e "\e[31m\n\n>\t Do you want to start and enable libvirtd?: systemctl start/enable libvirtd \e[0m\n"
    wanna_continue start_enable_libvirtd return
    echo -e "\e[31m\n\n>\t If this command lists kvm_intel or kvm_amd, KVM is properly configured:\e[0m\n"
    lsmod | grep kvm
    echo -e "\e[31m\n\n>\t PERMISSIONS:\e[0m\n"
    echo -e "\e[31m\n\n>\t passwd | egrep qemu:\e[0m\n"
    getent passwd | egrep qemu
    echo -e "\e[31m\n\n>\t /etc/libvirt/libvirtd.conf:\e[0m\n"
    sudo cat /etc/libvirt/libvirtd.conf | grep unix_sock_group
    sudo cat /etc/libvirt/libvirtd.conf | grep unix_sock_rw_perms
    echo -e "\e[31m\n\n>\t Set permissions on /etc/libvirt/libvirtd.conf?:\e[0m\n"
    wanna_continue change_libvirtd_file return
    echo -e "\e[31m\n\n>\t Add user $(whoami) to libvirt group?: getent group libvirt\e[0m\n "
    getent group libvirt
    wanna_continue add_to_group return
    echo -e "\e[31m\n\n>\t Config libvirt?:\e[0m\n "
    wanna_continue config_libvirt return
    echo -e "\e[31m\n\n>\t Start virt-manager?:\e[0m\n "
    wanna_continue virt-manager return
    echo -e "\e[31m\n\n>\t Virsh status....:\e[0m\n "
    virsh_status
}




network_creating_bridge_nat() {
    param1=$1
    param2=$2
cat <<EOF > virtnets/$param1.xml
<network>
  <name>$param1</name>
  <forward dev='wlp0s20f3' mode='nat'>
    <nat>
        <port start="1024" end="65535"/>
    </nat>
    <interface dev='wlp0s20f3'/>
  </forward>
  <bridge name='virbr$param2' stp='on' delay='0'/>
  <domain name='$param1'/>
  <ip address='192.168.168.1' netmask='255.255.255.252'>
  </ip>
</network>
EOF
    cat virtnets/$param1.xml
    virsh net-define --file virtnets/$param1.xml
    virsh net-start --network $param1
    virsh net-autostart --network $param1
}



network_creating_isolated() {
    param1=$1
    param2=$2
cat <<EOF > virtnets/$param1.xml
<network>
  <name>$param1</name>
  <bridge name='virbr$param2' stp='on' delay='0'/>
  <domain name='$param1'/>
</network>
EOF
    cat virtnets/$param1.xml
    virsh net-define --file virtnets/$param1.xml
    virsh net-start --network $param1
    virsh net-autostart --network $param1
}



network_config() {
    echo -e "\e[31m\n\n>\t HOST NETWORK CONFIGURATION:\e[0m\n"
    ip a
    virsh net-list --all
    echo -e "\e[31m\n\n>\t READING BRIDGE NETWORK:\e[0m\n"
    brctl show
    echo -e "\e[31m\n\n>\t NETWORK FILES: \e[0m\n"
    sudo ls -hals /etc/libvirt/qemu/networks
    echo -e "\e[31m\n\n>\t Ensure IP forwarding is enabled: this must be 1 \e[0m\n"
    cat /proc/sys/net/ipv4/ip_forward
    grep -q 1 /proc/sys/net/ipv4/ip_forward && echo forwarding-enable || echo forwarding-disable
    echo -e "\e[31m\n\n>\t Creating folder virtnets/ ... \e[0m\n"
    mkdir -p virtnets
    ls -hals | grep virtnets
    echo -e "\e[31m\n\n>\t Creating NET0:\e[0m\n"
    network_creating_bridge_nat net0-firewall 0
    echo -e "\e[31m\n\n>\t Creating NET1:\e[0m\n"
    network_creating_isolated net1-mgmt 1
    echo -e "\e[31m\n\n>\t Creating NET2:\e[0m\n"
    network_creating_isolated net2-personal 2
    echo -e "\e[31m\n\n>\t Creating NET3:\e[0m\n"
    network_creating_isolated net3-vault 3
    echo -e "\e[31m\n\n>\t Creating NET4:\e[0m\n"
    network_creating_isolated net4-dev 4
    echo -e "\e[31m\n\n>\t Creating NET5:\e[0m\n"
    network_creating_isolated net5-disposable 5
    echo -e "\e[31m\n\n>\t Creating NET6:\e[0m\n"
    network_creating_isolated net6-tor 6
    echo -e "\e[31m\n\n>\t Creating NET7:\e[0m\n"
    network_creating_isolated net7-ops 7
    echo -e "\e[31m\n\n>\t Creating NET8:\e[0m\n"
    network_creating_isolated net8-windows 8
    echo -e "\e[31m\n\n>\t Networking Summary:\e[0m\n"
    ip a
    virsh net-list --all
}

<<COMMENT
net0-firewall-pfsense.qcow2  
net1-mgmt-fedora.qcow2
net2-personal-fedora.qcow2  
net4-dev-fedora.qcow2       
net6-tor-tails.iso   
net7-ops-manjaro.qcow2    
net8-windows-win2k16.qcow2
net1-mgmt-fedora.qcow2       
net3-vault-fedora.qcow2     
net5-disposable-fedora.iso  
net7-ops-kali.qcow2  
net8-windows-win10.qcow2

net0-firewall
net1-mgmt
net2-personal
net3-vault
net4-dev
net5-disposable
net6-tor
net7-ops
net8-windows
COMMENT

vms_config() {
    vpath_pool_vms="vms/"
    vpath_pool_isos="isos/"
    vvm_n00="net00-firewall-pfsense"
    vvm_n10="net10-mgmt-fedora"
    vvm_n20="net20-personal-fedora"
    vvm_n30="net30-vault-fedora"
    vvm_n40="net40-dev-fedora"
    vvm_n50="net50-disposable-fedora"
    vvm_n60="net60-tor-tails"
    vvm_n70="net70-ops-manjaro"
    vvm_n71="net71-ops-kali"
    vvm_n80="net80-windows-win10"
    vvm_n81="net81-windows-win2k16"
    vnet0="net0-firewall"
    vnet1="net1-mgmt"
    vnet2="net2-personal"
    vnet3="net3-vault"
    vnet4="net4-dev"
    vnet5="net5-disposable"
    vnet6="net6-tor"
    vnet7="net7-ops"
    vnet8="net8-windows"
    echo -e "\e[31m\n\n>\t CREATING GUESTS WITH VIRT-INSTALL:\e[0m\n"
    
    echo -e "\e[31m\n\n>\t Creating NET0 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n00 \
        --memory 2048 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n00.qcow2 \
        --os-variant freebsd11.3 \
        --network network=$vnet0,model=virtio \
        --network network=$vnet1,model=virtio \
        --network network=$vnet2,model=virtio \
        --network network=$vnet3,model=virtio \
        --network network=$vnet4,model=virtio \
        --network network=$vnet5,model=virtio \
        --network network=$vnet6,model=virtio \
        --network network=$vnet7,model=virtio \
        --network network=$vnet8,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n00
    
    echo -e "\e[31m\n\n>\t Creating NET1 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n10 \
        --memory 2048 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n10.qcow2 \
        --os-variant fedora33 \
        --network network=$vnet1,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n10
    
    echo -e "\e[31m\n\n>\t Creating NET2 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n20 \
        --memory 4096 \
        --vcpus 2 \
        --disk vol=$vpath_pool_vms$vvm_n20.qcow2 \
        --os-variant fedora33 \
        --network network=$vnet2,model=virtio \
        --graphics spice,clipboard.copypaste=yes \
        --video qxl \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n20
    
    echo -e "\e[31m\n\n>\t Creating NET3 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n30 \
        --memory 2048 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n30.qcow2 \
        --os-variant fedora33 \
        --network network=$vnet3,model=virtio \
        --graphics spice,clipboard.copypaste=yes \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n30
    
    echo -e "\e[31m\n\n>\t Creating NET4 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n40 \
        --memory 8192 \
        --vcpus 4 \
        --disk vol=$vpath_pool_vms$vvm_n40.qcow2 \
        --os-variant fedora33 \
        --network network=$vnet4,model=virtio \
        --graphics spice,clipboard.copypaste=yes \
        --video qxl \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n40
    
    echo -e "\e[31m\n\n>\t Creating NET5 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n50 \
        --memory 2048 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n50.iso \
        --os-variant fedora33 \
        --network network=$vnet5,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n50
    
    echo -e "\e[31m\n\n>\t Creating NET6 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n60 \
        --memory 4096 \
        --vcpus 2 \
        --disk vol=$vpath_pool_vms$vvm_n60.iso \
        --os-variant debian10 \
        --network network=$vnet6,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n60
    
    echo -e "\e[31m\n\n>\t Creating NET7 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n70 \
        --memory 2048 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n70.qcow2 \
        --os-variant manjaro \
        --network network=$vnet7,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n70
    
    virt-install \
        --name $vvm_n71 \
        --memory 2048 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n71.qcow2 \
        --os-variant debian10 \
        --network network=$vnet7,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n71
    
    echo -e "\e[31m\n\n>\t Creating NET8 VM:\e[0m\n"
    
    virt-install \
        --name $vvm_n80 \
        --memory 4096 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n80.qcow2 \
        --os-variant win10 \
        --network network=$vnet8,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n80
    
    virt-install \
        --name $vvm_n81 \
        --memory 4096 \
        --vcpus 1 \
        --disk vol=$vpath_pool_vms$vvm_n81.qcow2 \
        --os-variant win2k16 \
        --network network=$vnet8,model=virtio \
        --graphics spice,clipboard.copypaste=no \
        --video virtio \
        --import \
        --noautoconsole
    #An inelegant shutdown, also known as hard-stop. This is equivalent to unplugging the power cable. 
    virsh destroy $vvm_n81
    
    echo -e "\e[31m\n\n>\t  VM Summary:\e[0m\n"
    virsh pool-list --all
    virsh list --all
}


start_enable_sshd() {
    sudo systemctl start sshd
    sudo systemctl enable sshd
    sudo systemctl status sshd
}

kvm_ssh() {
    echo -e "\e[31m\n\n>\t Verifing SSH: sshfs --version \e[0m\n"
    sshfs --version
    rpm -qa | grep -i sshfs
    echo -e "\e[31m\n\n>\t Do you want to install SSHFS?: dnf install fuse-sshfs \e[0m\n"
    wanna_continue "dnf install fuse-sshfs" return
    echo -e "\e[31m\n\n>\t SSH Deamon status: sudo systemctl enable sshd \e[0m\n"
    sudo systemctl status sshd
    echo -e "\e[31m\n\n>\t Do you want to start and enable libvirtd?: systemctl start/enable libvirtd \e[0m\n"
    wanna_continue start_enable_sshd return
}

kvm_verification() {
    echo -e "\e[31m\n\n>\t VIRT-INSTALL SUMMARY:\e[0m\n"   
    virsh list --all
    echo -e "\e[31m\n\n>\t BACKUP FILES:\e[0m\n" 
    echo -e ">\t sudo ls -hals /etc/libvirt/qemu/"
    echo -e ">\t sudo ls -hals /etc/libvirt/qemu/networks"
}

select_input() {
    echo -e
    PS3="Select the operation: "
}

formation_init() {
echo -e "\e[31m********************************************************************************************************************************"
echo -e "****************************************************** KVM Formation 1.0 *******************************************************"
echo -e "********************************************************************************************************************************\e[0m\n"
}

formation_end() {
echo -e
echo -e "\e[31m********************************************************************************************************************************"
echo -e "****************************************************** KVM Formation END *******************************************************"
echo -e "********************************************************************************************************************************\e[0m\n"
exit
}


select_menu() {
    select opt in installation network vms verification ssh virtManager quit; do
        case $opt in
            installation)
                install_virtualization
                break
                ;;
            network)
                network_config
                break
                ;;
            vms)
                vms_config
                break
                ;;
            verification)
                kvm_verification
                break
                ;;
            ssh)
                kvm_ssh
                break
                ;;
            virtManager)
                virt-manager
                break
                ;;    
            quit)
                formation_end
                ;;
            *) 
                echo -e
                echo "Invalid option $REPLY"
                break
                ;;
        esac
    done
}


formation_init
while true
do
    select_input
    select_menu
done


