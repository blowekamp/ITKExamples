#include "itkMeshFileReader.h"
#include "itkMeshFileWriter.h"
#include "itkQuadEdgeMesh.h"

#include "itkDelaunayConformingQuadEdgeMeshFilter.h"

int main( int argc, char* argv[] )
{
  // Error message and help.
  if( argc != 3 )
    {
    std::cerr << "Usage:" <<std::endl;
    std::cerr << argv[0] << " <InputFileName> <OutputFileName>" << std::endl;
    return EXIT_FAILURE;
    }

  // Basic types.
  const unsigned int    Dimension = 3;
  typedef double        CoordType;

  typedef itk::QuadEdgeMesh< CoordType, Dimension >          MeshType;

  // Read the file in.
  typedef itk::MeshFileReader< MeshType >                    ReaderType;
  ReaderType::Pointer reader = ReaderType::New( );
  reader->SetFileName( argv[1] );

  // Process the mesh.
  MeshType::Pointer mesh = reader->GetOutput( );
  typedef itk::DelaunayConformingQuadEdgeMeshFilter< MeshType, MeshType >
  DelaunayConformFilterType;
  DelaunayConformFilterType::Pointer filter = DelaunayConformFilterType::New();
  filter->SetInput( mesh );

  // Write the output.
  typedef itk::MeshFileWriter< MeshType >                    WriterType;
  WriterType::Pointer writer = WriterType::New( );
  writer->SetInput( filter->GetOutput( ) );
  writer->SetFileName( argv[2] );

  try
    {
    writer->Update();
    }
  catch( itk::ExceptionObject & error )
    {
    std::cerr << "Error: " << error << std::endl;
    return EXIT_FAILURE;
    }

  std::cout << "Number of Edge flipped performed: "
            << filter->GetNumberOfEdgeFlips() <<std::endl;

  return EXIT_SUCCESS;
}
