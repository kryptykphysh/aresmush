require_relative "../../plugin_test_loader"

module AresMUSH
  module Login
    describe Create do
      before do
        AresMUSH::Locale.stub(:translate).with("login.invalid_create_syntax") { "invalid_create_syntax" }
        AresMUSH::Locale.stub(:translate).with("login.player_name_taken") { "player_name_taken" }
        AresMUSH::Locale.stub(:translate).with("login.password_too_short") { "password_too_short" }
        AresMUSH::Locale.stub(:translate).with("login.player_created", { :name => "playername" }) { "player_created" }
      end
      
      describe :want_anon_command? do
        it "should want an anon command if the root is 'create'" do
          cmd = double(Command)
          cmd.stub(:root_is?).with("create") { true }
          create = Create.new(nil)
          create.want_anon_command?(cmd).should eq true
        end

        it "should not want an anon command if the root something else" do
          cmd = double(Command)
          cmd.stub(:root_is?).with("create") { false }
          create = Create.new(nil)
          create.want_anon_command?(cmd).should eq false
        end
      end

      describe :want_command? do
        it "should not want logged in commands" do
          cmd = double(Command)
          create = Create.new(nil)
          create.want_command?(cmd).should eq false
        end
      end
      
      # SUCCESS
      describe :on_command do
        before do
          @dispatcher = double(Dispatcher).as_null_object
          container = double(Container)
          container.stub(:dispatcher) { @dispatcher }

          @client = double(Client)
          @player = mock
          Player.stub(:exists?).with("playername") { false }
          Player.stub(:create_player) { @player }
          @client.stub(:emit_success)
          @client.stub(:player=)
          
          @cmd = Command.new(@client, "create playername password")
          @create = Create.new(container)
        end
        
        it "should create the player" do          
          Player.should_receive(:create_player).with("playername", "password")
          @create.on_command(@client, @cmd)                  
        end
        
        it "should accept a multi-word password" do
          cmd = Command.new(@client, "create playername bob's password")
          Player.should_receive(:create_player).with("playername", "bob's password")
          @create.on_command(@client, cmd)          
        end
        
        it "should tell the player they're created" do
          @client.should_receive(:emit_success).with("player_created")
          @create.on_command(@client, @cmd)                  
        end
        
        it "should set the player on the client" do
          @client.should_receive(:player=).with(@player)
          @create.on_command(@client, @cmd)                  
        end
        
        it "should dispatch the created event" do
          @dispatcher.should_receive(:on_event) do |type, args|
            type.should eq :player_created
            args[:client].should eq @client
          end
          @create.on_command(@client, @cmd)                  
        end
      end
      
      # FAILURE
      describe :on_command do
        before do
          @client = double(Client)
          @client.stub(:player) { }
          @create = Create.new(nil)
        end
        
        it "should fail if user/password isn't specified" do
          cmd = Command.new(@client, "create")
          @client.should_receive(:emit_failure).with("invalid_create_syntax")
          @create.on_command(@client, cmd)        
        end

        it "should fail if password isn't specified" do
          cmd = Command.new(@client, "create playername")
          @client.should_receive(:emit_failure).with("invalid_create_syntax")
          @create.on_command(@client, cmd)        
        end
        
        it "should fail if password is too short" do
          cmd = Command.new(@client, "create playername bar")
          @client.should_receive(:emit_failure).with("password_too_short")
          @create.on_command(@client, cmd)        
        end
        
        it "should fail if the player already exists" do
          cmd = Command.new(@client, "create playername password")
          Player.stub(:exists?).with("playername") { true }
          @client.should_receive(:emit_failure).with("player_name_taken")
          @create.on_command(@client, cmd)                  
        end
      end
    end
  end
end

