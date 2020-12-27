# HashTable and RunSpace for GUI
$syncHash = [hashtable]::Synchronized(@{})
$newRunspace = [runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"         
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)      

$syncHash.globalFunctions = @'

function Write-StatusProgress ($msg, $pct) {

    $syncHash.Form.Dispatcher.Invoke([action] {
        $syncHash.WPFStatusTextBlock.Text = $msg
        if (-not [string]::IsNullOrEmpty($pct)) {
            $syncHash.WPFProgressBar.Value = $pct
        }
            }, "Render"
    )
}

function Write-Error ($msg = 'error') {

    $syncHash.Form.Dispatcher.Invoke([action] {
        $syncHash.WPFStatusTextBlock.Text = $msg
        $syncHash.WPFStatusTextBlock.Foreground = 'Red'
        $syncHash.WPFProgressBar.Foreground = 'Red'
            }, "Render"
    )
}

'@

# Build UI and add to RunSpace
$psCmd = [PowerShell]::Create().AddScript( {
        # Loading global shared functions
        Invoke-Expression $syncHash.globalFunctions

        $inputXML = @"
<Window x:Class="WpfApp2.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp2"
        mc:Ignorable="d"
        Title="startDD" Height="257.616" Width="419.375" MaxHeight="257.616" MaxWidth="419.375" ResizeMode="CanMinimize">
    <Grid Margin="0,0,0.5,0">
        <Grid.ColumnDefinitions>
            <ColumnDefinition/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition/>
        </Grid.RowDefinitions>
        <CheckBox Name="MRACheckBox" Content="Remoteapp mode" HorizontalAlignment="Left" Margin="12,40,0,0" VerticalAlignment="Top" Height="31" Width="150"/>
        <Button Name="StartButton" Content="Start" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="75" Height="20"/>
        <ProgressBar Name="ProgressBar" HorizontalAlignment="Left" Height="10" Margin="100,15,0,0" VerticalAlignment="Top" Width="295"/>
        <Label Content="Status:" HorizontalAlignment="Left" Margin="10,190,0,-52.5" VerticalAlignment="Top" Width="46" Height="26" FontWeight="Bold"/>
        <Label Content="User VMs" HorizontalAlignment="Left" Margin="10,64,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
        <TextBlock Name="StatusTextBlock" HorizontalAlignment="Left" Margin="61,195,0,-57.5" TextWrapping="Wrap" Text="loading..." VerticalAlignment="Top" Width="330" Height="26"/>
        <DataGrid Name="DataGrid" Height="90" HorizontalAlignment="Left" Margin="12,95,0,0" Width="380" HorizontalGridLinesBrush="Gray" VerticalGridLinesBrush="Gray" VerticalAlignment="Top">
            <DataGrid.Columns>
                <DataGridTextColumn Header="State" Binding="{Binding State}" Width="Auto" IsReadOnly="True">
                <DataGridTextColumn.ElementStyle>
                <Style TargetType="{x:Type TextBlock}">
                    <Style.Triggers>
                        <Trigger Property="Text" Value="NOK">
                            <Setter Property="Background" Value="Red"/>
                        </Trigger>
                        <Trigger Property="Text" Value="OK">
                        <Setter Property="Background" Value="LightGreen"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
                </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="Auto" IsReadOnly="True"/>
                <DataGridTextColumn Header="IP" Binding="{Binding IP}" Width="Auto" IsReadOnly="True"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="Auto" IsReadOnly="True"/>
                <DataGridTextColumn Header="Expiration" Binding="{Binding Expiration}" Width="1*" IsReadOnly="True"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@

        $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
        [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

        [xml]$xaml = $inputXML

        #Read XAML 
        $reader = (New-Object System.Xml.XmlNodeReader $xaml) 
        $syncHash.Form = [Windows.Markup.XamlReader]::Load( $reader )

        # Store Form Objects In PowerShell
        $xaml.SelectNodes("//*[@Name]") | ForEach-Object { $syncHash."WPF$($_.Name)" = $syncHash.Form.FindName($_.Name) }

        function Write-FormHost {
            param( [string]$Text )

            $syncHash.Form.Dispatcher.Invoke(
                [action] { $syncHash.WPFStatusTextBlock.Text = $Text }, "Render"
            )
        }

        function Write-FormHostError {
            param( [string]$Text )

            $syncHash.Form.Dispatcher.Invoke([action] { 
                $syncHash.WPFStatusTextBlock.Text = $Text 
                $syncHash.WPFStatusTextBlock.Foreground = 'Red'
                $syncHash.WPFProgressBar.Foreground = 'Red'
                }, "Render"
            )
        }

        function Get-Settings {
            Write-StatusProgress "settings loaded extra long message for testing field lenght" 
            if ($env:SDD_REMOTEAPP -eq $true) {
                $syncHash.WPFMRACheckBox.IsChecked = $true
            }
            else {
                $syncHash.WPFMRACheckBox.IsChecked = $false   
            }
        }

        $syncHash.WPFMRACheckBox.Add_Click( { 
       
                $saverunspace = [runspacefactory]::CreateRunspace()
                $saverunspace.ApartmentState = "STA"
                $saverunspace.ThreadOptions = "ReuseThread"
                $saverunspace.Open()
                $saverunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
        
                $syncHash.mode = $syncHash.WPFMRACheckBox.IsChecked
                $syncHash.f = $syncHash.globalFunctions

                $code = {
                    Invoke-Expression $syncHash.f
                    
                    [System.Environment]::SetEnvironmentVariable('SDD_REMOTEAPP', $syncHash.mode , [System.EnvironmentVariableTarget]::User)

                    Write-StatusProgress "setings saved"
                }

                $PSInstance = [powershell]::Create().AddScript($code)
                $PSinstance.Runspace = $saverunspace
                $job = $PSinstance.BeginInvoke()
            });

        $syncHash.WPFStartButton.Add_Click( { 
        
                $syncHash.WPFStartButton.IsEnabled = $False

                $btnrunspace = [runspacefactory]::CreateRunspace()
                $btnrunspace.ApartmentState = "STA"
                $btnrunspace.ThreadOptions = "ReuseThread"
                $btnrunspace.Open()
                $btnrunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)

                $syncHash.remoteAppMode = $syncHash.WPFMRACheckBox.IsChecked
                $syncHash.f = $syncHash.globalFunctions
              
                $code = {
                    Invoke-Expression $syncHash.f
                    function StartButtonEnable {
                        $syncHash.Form.Dispatcher.Invoke(
                            [action] { $syncHash.WPFStartButton.IsEnabled = $true })
                    }
      
                    function LoadProgress ($msg = "loading"){
                        For ($i = 0; $i -le 10; $i++) {
                            Write-StatusProgress "$($msg) ." $i
                            Start-Sleep -Milliseconds 100
                            Write-StatusProgress "$($msg) .."
                            Start-Sleep -Milliseconds 100
                            Write-StatusProgress "$($msg) ..."
                            Start-Sleep -Milliseconds 100
                        }
                    }

                    function LoadGrid {

                        $syncHash.Form.Dispatcher.Invoke([action] { 
                                
                            $syncHash.WPFDatagrid.AddChild([pscustomobject]@{Name = 'vm-name1'; IP = '10.2.1.1'; State = 'OK'; Expiration = '14 days' })
                            $syncHash.WPFDatagrid.AddChild([pscustomobject]@{Name = 'vm-name1'; IP = '10.2.1.1'; State = 'OK'; Expiration = '14 days' })

                            }, "Render"
                        )
                    }

                    function FetchData {

                        if (-not $syncHash.dataFetching){
                            
                            $syncHash.dataFetching = $true
                            $syncHash.dataLoadError = $null
                            
                            $datarunspace = [runspacefactory]::CreateRunspace()
                            $datarunspace.ApartmentState = "STA"
                            $datarunspace.ThreadOptions = "ReuseThread"
                            $datarunspace.Open()
                            $datarunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
                            
                            $syncHash.f = $syncHash.globalFunctions

                            $code = {

                                Invoke-Expression $syncHash.f
                                "running fetch `n" | Out-File -FilePath out.log -Append -Force
                                Start-Sleep 5
                                $syncHash.dataFetching = $null                               
                                $syncHash.dataLoadError = $false
                            }
    
                            $PSInstance = [powershell]::Create().AddScript($code)
                            $PSinstance.Runspace = $datarunspace
                            $dataJob = $PSinstance.BeginInvoke()
    
                        } else {
                            return $dataJob.isCompleted
                        }

                    }

                    #Do {
                    #    LoadProgress "fetching data"  
                    #} while (FetchData) 
                    
                    FetchData

                    Do {
                        LoadProgress "fetching data"
                    } while ([string]::IsNullOrEmpty($syncHash.dataLoadError))

                    if ($syncHash.dataLoadError) { Write-Error "failed to load data"} else { Write-StatusProgress "data loaded"}

                    LoadGrid
                    StartButtonEnable

                }
        
                $PSInstance = [powershell]::Create().AddScript($code)
                $PSinstance.Runspace = $btnrunspace
                $job = $PSinstance.BeginInvoke()

                $Runspace.Close()
                $Runspace.Dispose()

            });

        Get-Settings
        #Write-FormHostError "failed to load settings"

        # Finalize and close gui runspace upon exit
        $syncHash.Form.ShowDialog() | Out-Null
        $syncHash.Error = $Error
        $Runspace.Close()
        $Runspace.Dispose()
    });

# Load runspace with gui
$psCmd.Runspace = $newRunspace
$data = $psCmd.BeginInvoke()
