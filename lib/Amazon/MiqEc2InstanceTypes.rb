require 'active_support'  #TODO - Make this work without Rails

module MiqEc2InstanceTypes
  # From http://aws.amazon.com/ec2/instance-types
  # and http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/instance-types.html#AvailableInstanceTypes
  AVAILABLE_TYPES = {
    "t1.micro" => {
      :name                    => "t1.micro",
      :family                  => "Micro",
      :description             => "Micro Instance",
      :default                 => false,
      :memory                  => 615.megabytes,
      :cpu_total               => 0..2,
      :cpu_units               => 0..2,
      :cpu_cores               => 1,
      :instance_store_size     => nil,
      :instance_store_volumes  => nil,
      :architecture            => [:i386, :x86_64],
      :network_performance     => :very_low,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "m1.small" => {
      :name                    => "m1.small",
      :family                  => "Standard",
      :description             => "Small Instance",
      :default                 => true,
      :memory                  => 1.7.gigabytes,
      :cpu_total               => 1,
      :cpu_units               => 1,
      :cpu_cores               => 1,
      :instance_store_size     => 160.gigabytes,
      :instance_store_volumes  => 1,
      :architecture            => [:i386, :x86_64],
      :network_performance     => :low,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "m1.medium" => {
      :name                    => "m1.medium",
      :family                  => "Standard",
      :description             => "Medium Instance",
      :default                 => false,
      :memory                  => 3.75.gigabytes,
      :cpu_total               => 2,
      :cpu_units               => 2,
      :cpu_cores               => 1,
      :instance_store_size     => 410.gigabytes,
      :instance_store_volumes  => 1,
      :architecture            => [:i386, :x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "m1.large" => {
      :name                    => "m1.large",
      :family                  => "Standard",
      :description             => "Large Instance",
      :default                 => false,
      :memory                  => 7.5.gigabytes,
      :cpu_total               => 4,
      :cpu_units               => 2,
      :cpu_cores               => 2,
      :instance_store_size     => 840.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => 500, # Mbps
      :spot_instance_available => true,
    },

    "m1.xlarge" => {
      :name                    => "m1.xlarge",
      :family                  => "Standard",
      :description             => "Extra Large (M1) Instance",
      :default                 => false,
      :memory                  => 15.gigabytes,
      :cpu_total               => 8,
      :cpu_units               => 2,
      :cpu_cores               => 4,
      :instance_store_size     => 1680.gigabytes,
      :instance_store_volumes  => 4,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => 1000, # Mbps
      :spot_instance_available => true,
    },

    "m2.xlarge" => {
      :name                    => "m2.xlarge",
      :family                  => "High-Memory",
      :description             => "High-Memory Extra Large Instance",
      :default                 => false,
      :memory                  => 17.1.gigabytes,
      :cpu_total               => 6.5,
      :cpu_units               => 3.25,
      :cpu_cores               => 2,
      :instance_store_size     => 420.gigabytes,
      :instance_store_volumes  => 1,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "m2.2xlarge" => {
      :name                    => "m2.2xlarge",
      :family                  => "High-Memory",
      :description             => "High-Memory Double Extra Large Instance",
      :default                 => false,
      :memory                  => 34.2.gigabytes,
      :cpu_total               => 13,
      :cpu_units               => 3.25,
      :cpu_cores               => 4,
      :instance_store_size     => 850.gigabytes,
      :instance_store_volumes  => 1,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => 500, # Mbps
      :spot_instance_available => true,
    },

    "m2.4xlarge" => {
      :name                    => "m2.4xlarge",
      :family                  => "High-Memory",
      :description             => "High-Memory Quadruple Extra Large Instance",
      :default                 => false,
      :memory                  => 68.4.gigabytes,
      :cpu_total               => 26,
      :cpu_units               => 3.25,
      :cpu_cores               => 8,
      :instance_store_size     => 1680.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => 1000, # Mbps
      :spot_instance_available => true,
    },

    "m3.medium" => {
      :name                    => "m3.medium",
      :family                  => "Standard",
      :description             => "Medium (M3) Instance",
      :default                 => false,
      :memory                  => 3.75.gigabytes,
      :cpu_total               => 3,
      :cpu_units               => 3,
      :cpu_cores               => 1,
      :instance_store_size     => :ebs_only,
      :instance_store_volumes  => :ebs_only,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "m3.large" => {
      :name                    => "m3.large",
      :family                  => "Standard",
      :description             => "Large (M3) Instance",
      :default                 => false,
      :memory                  => 7.5.gigabytes,
      :cpu_total               => 6.5,
      :cpu_units               => 3.25,
      :cpu_cores               => 2,
      :instance_store_size     => :ebs_only,
      :instance_store_volumes  => :ebs_only,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => 500, # Mbps
      :spot_instance_available => true,
    },

    "m3.xlarge" => {
      :name                    => "m3.xlarge",
      :family                  => "Standard",
      :description             => "Extra Large (M3) Instance",
      :default                 => false,
      :memory                  => 15.gigabytes,
      :cpu_total               => 13,
      :cpu_units               => 3.25,
      :cpu_cores               => 4,
      :instance_store_size     => :ebs_only,
      :instance_store_volumes  => :ebs_only,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "m3.2xlarge" => {
      :name                    => "m3.2xlarge",
      :family                  => "Standard",
      :description             => "Double Extra Large Instance",
      :default                 => false,
      :memory                  => 30.gigabytes,
      :cpu_total               => 26,
      :cpu_units               => 3.25,
      :cpu_cores               => 8,
      :instance_store_size     => :ebs_only,
      :instance_store_volumes  => :ebs_only,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => 1000, # Mbps
      :spot_instance_available => true,
    },

    "c1.medium" => {
      :name                    => "c1.medium",
      :family                  => "High-CPU",
      :description             => "High-CPU Medium Instance",
      :default                 => false,
      :memory                  => 1.7.gigabytes,
      :cpu_total               => 5,
      :cpu_units               => 2.5,
      :cpu_cores               => 2,
      :instance_store_size     => 350.gigabytes,
      :instance_store_volumes  => 1,
      :architecture            => [:i386, :x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "c1.xlarge" => {
      :name                    => "c1.xlarge",
      :family                  => "High-CPU",
      :description             => "High-CPU Extra Large Instance",
      :default                 => false,
      :memory                  => 7.gigabytes,
      :cpu_total               => 20,
      :cpu_units               => 2.5,
      :cpu_cores               => 8,
      :instance_store_size     => 1680.gigabytes,
      :instance_store_volumes  => 4,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => 1000, # Mbps
      :spot_instance_available => true,
    },

    "c3.large" => {
      :name                    => "c3.large",
      :family                  => "High-CPU",
      :description             => "High-CPU Large Instance",
      :default                 => false,
      :memory                  => 3.75.gigabytes,
      :cpu_total               => 7,
      :cpu_units               => 3.5,
      :cpu_cores               => 2,
      :instance_store_size     => 32.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "c3.xlarge" => {
      :name                    => "c3.xlarge",
      :family                  => "High-CPU",
      :description             => "High-CPU Extra Large Instance",
      :default                 => false,
      :memory                  => 7.5.gigabytes,
      :cpu_total               => 14,
      :cpu_units               => 3.5,
      :cpu_cores               => 4,
      :instance_store_size     => 80.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "c3.2xlarge" => {
      :name                    => "c3.2xlarge",
      :family                  => "High-CPU",
      :description             => "High-CPU Double Extra Large Instance",
      :default                 => false,
      :memory                  => 15.gigabytes,
      :cpu_total               => 28,
      :cpu_units               => 3.5,
      :cpu_cores               => 8,
      :instance_store_size     => 160.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "c3.4xlarge" => {
      :name                    => "c3.4xlarge",
      :family                  => "High-CPU",
      :description             => "High-CPU Quadruple Extra Large Instance",
      :default                 => false,
      :memory                  => 30.gigabytes,
      :cpu_total               => 55,
      :cpu_units               => 3.4375,
      :cpu_cores               => 16,
      :instance_store_size     => 320.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "c3.8xlarge" => {
      :name                    => "c3.8xlarge",
      :family                  => "High-CPU",
      :description             => "High-CPU Eight Extra Large Instance",
      :default                 => false,
      :memory                  => 60.gigabytes,
      :cpu_total               => 108,
      :cpu_units               => 3.375,
      :cpu_cores               => 32,
      :instance_store_size     => 640.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "cc2.8xlarge" => {
      :name                    => "cc2.8xlarge",
      :family                  => "Cluster Compute",
      :description             => "Cluster Compute Eight Extra Large Instance",
      :default                 => false,
      :memory                  => 60.5.gigabytes,
      :cpu_total               => 88,
      :cpu_units               => 5.5,
      :cpu_cores               => 16, # 2 x Intel Xeon E5-2670, eight-core with hyperthread
      :instance_store_size     => 3360.gigabytes,
      :instance_store_volumes  => 4,
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "cg1.4xlarge" => {
      :name                    => "cg1.4xlarge",
      :family                  => "Cluster GPU",
      :description             => "Cluster GPU Quadruple Extra Large Instance",
      :default                 => false,
      :memory                  => 22.5.gigabytes,
      :cpu_total               => 33.5,
      :cpu_units               => 4.1875,
      :cpu_cores               => 8, # 2 x Intel Xeon X5570, quad-core with hyperthread, plus 2 NVIDIA Tesla M2050 GPUs
      :instance_store_size     => 1680.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "g2.2xlarge" => {
      :name                    => "g2.2xlarge",
      :family                  => "GPU",
      :description             => "GPU Double Extra Large Instance",
      :default                 => false,
      :memory                  => 15.gigabytes,
      :cpu_total               => 26,
      :cpu_units               => 3.25,
      :cpu_cores               => 8,
      :instance_store_size     => 60.gigabytes,
      :instance_store_volumes  => 1,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },

    "hi1.4xlarge" => {
      :name                    => "hi1.4xlarge",
      :family                  => "High I/O",
      :description             => "High I/O Quadruple Extra Large Instance",
      :default                 => false,
      :memory                  => 60.5.gigabytes,
      :cpu_total               => 35,
      :cpu_units               => 4.37,
      :cpu_cores               => 8,
      :instance_store_size     => 2.terabytes,
      :instance_store_volumes  => 2, # based on solid-state drive (SSD) technology
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => false,
    },

    "cr1.8xlarge" => {
      :name                    => "cr1.8xlarge",
      :family                  => "High-Memory Cluster",
      :description             => "High-Memory Cluster Eight Extra Large Instance",
      :default                 => false,
      :memory                  => 244.gigabytes,
      :cpu_total               => 88,
      :cpu_units               => 5.5,
      :cpu_cores               => 16, # 2 x Intel Xeon E5-2670, eight-core
      :instance_store_size     => 240.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => false,
    },

    "hs1.8xlarge" => {
      :name                    => "hs1.8xlarge",
      :family                  => "High Storage",
      :description             => "High Storage Eight Extra Large Instance",
      :default                 => false,
      :memory                  => 117.gigabytes,
      :cpu_total               => 35,
      :cpu_units               => 6.36,
      :cpu_cores               => 16, # 8 cores + 8 hyperthreads
      :instance_store_size     => 48.terabytes,
      :instance_store_volumes  => 24,
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => false,
    },

    "i2.xlarge" => {
      :name                    => "i2.xlarge",
      :family                  => "Storage Optimized",
      :description             => "Storage Optimized Extra Large Instance",
      :default                 => false,
      :memory                  => 30.5.gigabytes,
      :cpu_total               => 14,
      :cpu_units               => 3.5,
      :cpu_cores               => 4,
      :instance_store_size     => 800.gigabytes,
      :instance_store_volumes  => 1,
      :architecture            => [:x86_64],
      :network_performance     => :moderate,
      :ebs_optimized_available => nil,
      :spot_instance_available => false,
    },

    "i2.2xlarge" => {
      :name                    => "i2.2xlarge",
      :family                  => "Storage Optimized",
      :description             => "Storage Optimized Double Extra Large Instance",
      :default                 => false,
      :memory                  => 61.gigabytes,
      :cpu_total               => 27,
      :cpu_units               => 3.375,
      :cpu_cores               => 8,
      :instance_store_size     => 1600.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => nil,
      :spot_instance_available => false,
    },

    "i2.4xlarge" => {
      :name                    => "i2.4xlarge",
      :family                  => "Storage Optimized",
      :description             => "Storage Optimized Quadruple Extra Large Instance",
      :default                 => false,
      :memory                  => 122.gigabytes,
      :cpu_total               => 53,
      :cpu_units               => 3.3125,
      :cpu_cores               => 16,
      :instance_store_size     => 3200.gigabytes,
      :instance_store_volumes  => 4,
      :architecture            => [:x86_64],
      :network_performance     => :high,
      :ebs_optimized_available => nil,
      :spot_instance_available => false,
    },

    "i2.8xlarge" => {
      :name                    => "i2.8xlarge",
      :family                  => "Storage Optimized",
      :description             => "Storage Optimized Eight Extra Large Instance",
      :default                 => false,
      :memory                  => 244.gigabytes,
      :cpu_total               => 104,
      :cpu_units               => 3.25,
      :cpu_cores               => 32,
      :instance_store_size     => 6400.gigabytes,
      :instance_store_volumes  => 8,
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => false,
    },
  }

  DISCONTINUED_TYPES = {
    "cc1.4xlarge" => {
      :disabled                => true,
      :name                    => "cc1.4xlarge",
      :family                  => "Cluster Compute",
      :description             => "Cluster Compute Quadruple Extra Large Instance",
      :default                 => false,
      :memory                  => 23.gigabytes,
      :cpu_total               => 33.5,
      :cpu_units               => 16.75,
      :cpu_cores               => 2,
      :instance_store_size     => 1680.gigabytes,
      :instance_store_volumes  => 2,
      :architecture            => [:x86_64],
      :network_performance     => :very_high,
      :ebs_optimized_available => nil,
      :spot_instance_available => true,
    },
  }

  def self.all
    AVAILABLE_TYPES.values + DISCONTINUED_TYPES.values
  end

  def self.names
    AVAILABLE_TYPES.keys + DISCONTINUED_TYPES.keys
  end
end
