kernel_version=$(uname -r)
os_name=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
system_version=$(lsb_release -rs)
architecture=$(uname -m)
btf_file="${kernel_version}.btf.tar.xz"
target_vmlinux_path="/usr/lib/modules/${kernel_version}/kernel/vmlinux"

download_url="https://mizar-share.cloud.infini-ai.com/packages/btfhub-archive/${os_name}/${system_version}/${architecture}/${btf_file}"

echo "Downloading ${btf_file} from ${download_url}..."
wget "$download_url"

if [ $? -ne 0 ]; then
    echo "Error: Download failed."
    exit 1
else
    echo "Download completed successfully."
fi

echo "Unpacking $btf_file..."
tar -xf "$btf_file"

unpacked_btf_file="${btf_file%.tar.xz}"
if [ ! -f "$unpacked_btf_file" ]; then
    echo "Error: ${kernel_version}.btf file does not exist after unpacking."
    exit 1
fi

echo "Creating directory $(dirname "$target_vmlinux_path")..."
sudo mkdir -p "$(dirname "$target_vmlinux_path")"

echo "Moving $unpacked_btf_file to $target_vmlinux_path..."
sudo mv "$unpacked_btf_file" "$target_vmlinux_path"

echo "Clean ${btf_file}..."
sudo rm $btf_file*

echo "Script completed successfully."