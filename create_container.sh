#!/bin/bash


NETWORK_NAMESPACE=plop
VETH_HOST=veth0
VETH_HOST_IP=10.10.10.1/24
VPEER_NS=veth1
VPEER_NS_IP=10.10.10.2/24

function create_network_namespace () {
	# create namespace
	if ! sudo ip netns list | grep -q "^\<${NETWORK_NAMESPACE}\>"; then
		echo "Create network namespace ${NETWORK_NAMESPACE}"
		sudo ip netns add "${NETWORK_NAMESPACE}"
	else
		echo "=> Network namespace ${NETWORK_NAMESPACE} already created!"
	fi

	# create veth pair
	if ! sudo ip link list| grep -q "\<${VETH_HOST}\>"; then
		echo "Create veth pair"
		sudo ip link add "${VETH_HOST}" type veth peer name "${VPEER_NS}"
	else
		echo "=> Veth pair already created!"
	fi
	
	# assign vpeer to namespace
	if ! sudo ip netns exec "${NETWORK_NAMESPACE}" ip link list | grep -q "\<${VPEER_NS}\>"; then
		echo "Assign veth ${VPEER_NS} to namespace ${NETWORK_NAMESPACE}"
		sudo ip link set "${VPEER_NS}" netns "${NETWORK_NAMESPACE}"
	else
		echo "=> Veth ${VPEER_NS} already assigned to network namespace ${NETWORK_NAMESPACE}!"
	fi
	
	# configure IP to vpeer in namespace
	if ! sudo ip netns exec "${NETWORK_NAMESPACE}" ip addr show "${VPEER_NS}" | grep -q "\<${VPEER_NS_IP}\>"; then
		echo "Set ip ${VPEER_NS_IP} to ${VPEER_NS} in ${NETWORK_NAMESPACE} namespace"
		sudo ip netns exec "${NETWORK_NAMESPACE}" ip addr add "${VPEER_NS_IP}" dev ${VPEER_NS}
		sudo ip netns exec "${NETWORK_NAMESPACE}" ip link set "${VPEER_NS}" up
		sudo ip netns exec "${NETWORK_NAMESPACE}" ip link set lo up
		sudo ip netns exec "${NETWORK_NAMESPACE}" ip route add default via "${VETH_HOST_IP%/*}"
		

	else
		echo "=> IP of ${VPEER_NS} in ${NETWORK_NAMESPACE} namespace already set!"
	fi

	# configure IP to veth of host
	if ! ip addr show "${VETH_HOST}" | grep -q "\<${VETH_HOST_IP}\>"; then
		echo "Set ip ${VETH_HOST_IP} to ${VETH_HOST} of host"
		sudo ip addr add "${VETH_HOST_IP}" dev ${VETH_HOST}
		sudo ip link set ${VETH_HOST} up
	else
		echo "=> IP of ${VETH_HOST} already set!"
	fi
	
	default_eth="$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^[:space:]]*\).*/\1/p')"
	
	# Activate ip_forward
	sudo /bin/bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

	# Flush forward rules.
	sudo iptables -P FORWARD DROP
	sudo iptables -F FORWARD
	 
	# Flush nat rules.
	sudo iptables -t nat -F

	# Enable masquerading
	sudo iptables -t nat -A POSTROUTING -s "${VETH_HOST_IP}" -o ${default_eth} -j MASQUERADE
	 
	sudo iptables -A FORWARD -i ${default_eth} -o ${VETH_HOST} -j ACCEPT
	sudo iptables -A FORWARD -o ${default_eth} -i ${VETH_HOST} -j ACCEPT

}



create_network_namespace

